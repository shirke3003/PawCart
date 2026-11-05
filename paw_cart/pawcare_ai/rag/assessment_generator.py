from groq import Groq
from config import GROQ_API_KEY, GROQ_MODEL
from rag.retriever import retrieve_knowledge
from app.assessment_questions import get_assessment_questions
from rag.grounding_validator import validate_grounding

client = Groq(api_key=GROQ_API_KEY)

MAX_ASSESSMENT_SOURCES = 5


def collect_assessment_knowledge(species, questions, answers):

    """
    Retrieve evidence once per answered questionnaire topic.

    A single combined query contained words from every question
    ("water", "food", "grooming"...), so category detection always
    locked onto the same category and the other topics (litter,
    exercise, enclosure, grooming) never reached the evidence.
    Per-topic retrieval keeps each topic's own category filter.
    """

    merged = {}

    for question in questions:

        answer = answers.get(question["id"])

        if not answer:
            continue

        if question["id"] == "concern":

            if answer.lower().startswith("no particular"):
                continue

            topic = f"{species} care concern: {answer}"

        else:

            topic = question["question"]

        for document in retrieve_knowledge(
            query=topic,
            species=species,
            top_k=2
        ):

            key = document["title"]

            if (
                key not in merged
                or document["similarity"] > merged[key]["similarity"]
            ):
                merged[key] = document

    documents = sorted(
        merged.values(),
        key=lambda d: d["similarity"],
        reverse=True
    )

    return documents[:MAX_ASSESSMENT_SOURCES]


def generate_assessment(species, pet_name, answers):

    questions = get_assessment_questions(species)

    if not questions:
        return {
            "status": "unsupported_species",
            "assessment": "This pet species is not currently supported.",
            "sources": []
        }

    question_map = {
        question["id"]: question["question"]
        for question in questions
    }

    formatted_answers = []

    for question_id, answer in answers.items():

        question = question_map.get(question_id)

        if question:
            formatted_answers.append(
                f"{question}: {answer}"
            )

    if not formatted_answers:
        return {
            "status": "insufficient_information",
            "assessment": (
                "No valid questionnaire answers were provided."
            ),
            "sources": []
        }

    user_context = "\n".join(formatted_answers)

    knowledge = collect_assessment_knowledge(
        species,
        questions,
        answers
    )

    if not knowledge:
        return {
            "status": "insufficient_information",
            "assessment": (
                "The current knowledge base does not contain "
                "sufficient relevant information to generate "
                "this assessment. Please consult a qualified "
                "veterinarian for professional guidance."
            ),
            "sources": []
        }

    evidence_sections = []

    for index, item in enumerate(knowledge, start=1):

        evidence_sections.append(
            f"""
[S{index}]
Title: {item['title']}
Species: {item['species']}
Category: {item['category']}
Information: {item['content']}
Source: {item['source']}
Source URL: {item['source_url']}
"""
        )

    context = "\n".join(evidence_sections)

    prompt = f"""
You are PawCare AI, an evidence-grounded pet-care
assessment assistant inside the PawCart application.

PET SPECIES: {species}
PET NAME: {pet_name or "Not provided"}

QUESTIONNAIRE ANSWERS:
{user_context}

RETRIEVED KNOWLEDGE:
{context}

STRICT GROUNDING RULES:

1. Treat questionnaire answers as information reported
   by the pet owner, not independently verified facts.

2. Use retrieved knowledge as the only source for
   veterinary and pet-care factual claims.

3. Every factual pet-care claim must end with a source
   reference such as [S1] or [S2]. Write each citation as
   its own bracket, e.g. [S1] [S2]; never [S1, S2] or (S1).

4. Never invent recommendations, symptoms, diagnoses,
   feeding schedules or medical facts.

5. Do not infer that a pet has a health problem from
   a questionnaire answer alone.

6. Do not describe a habit as good or bad unless the
   retrieved evidence supports that evaluation.

7. Do not mention retrieval similarity scores.

8. If the knowledge base does not cover a questionnaire
   topic, explicitly say that there is insufficient
   information to evaluate that topic (no citation needed
   for that statement).

9. Never fabricate citations.

10. Recommend professional veterinary evaluation for
    health concerns without attempting a diagnosis.

RETURN THE ASSESSMENT USING THESE SECTIONS:

OVERALL SUMMARY:
Summarize the owner's answers without making unsupported
medical conclusions.

OBSERVATIONS FROM YOUR ANSWERS:
List the information reported by the owner.

WHAT IS GOING WELL:
Mention only positive observations supported by
retrieved evidence. If none can be established, say so.

AREAS TO REVIEW:
Mention only areas that retrieved evidence supports.
Clearly identify topics that cannot be evaluated.

RECOMMENDED NEXT STEPS:
Give only evidence-supported actions.

WHEN TO CONTACT A VET:
Provide only relevant veterinary guidance supported
by retrieved evidence. Otherwise, state that the
knowledge base does not contain specific guidance.

Keep the response friendly, clear and concise.
"""

    try:

        completion = client.chat.completions.create(
            model=GROQ_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an evidence-grounded pet-care "
                        "assessment assistant. Never invent "
                        "veterinary facts or citations."
                    )
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.1
        )

        assessment = completion.choices[0].message.content

        if not assessment or not assessment.strip():
            raise ValueError("Groq returned an empty response.")

    except Exception as error:

        print("PawCare assessment generation failed:", error)

        return {
            "status": "generation_failed",
            "pet_name": pet_name,
            "species": species,
            "assessment": (
                "PawCare AI could not generate the assessment just "
                "now. Please try again."
            ),
            "removed_claims": [],
            "citation_check": {"status": "not_completed"},
            "sources": []
        }

    validation = validate_grounding(
        answer=assessment,
        knowledge=knowledge
    )

    return {
        "status": (
            "success"
            if validation["status"] == "validated"
            else "validation_failed"
        ),
        "pet_name": pet_name,
        "species": species,
        "assessment": validation["answer"],
        "removed_claims": validation["removed_claims"],
        "citation_check": validation["citation_check"],
        "sources": [
            {
                "reference": f"S{index}",
                "title": item["title"],
                "source": item["source"],
                "url": item["source_url"],
                "similarity": item["similarity"]
            }
            for index, item in enumerate(knowledge, start=1)
        ]
    }
