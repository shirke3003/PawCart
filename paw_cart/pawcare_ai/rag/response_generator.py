import re

from groq import Groq

from config import GROQ_API_KEY, GROQ_MODEL

from rag.retriever import (
    retrieve_knowledge,
    detect_categories,
    strip_pet_name,
    CATEGORY_KEYWORDS
)

from rag.grounding_validator import (
    validate_grounding,
    extract_citations,
    MISSING_INFO_LINE
)


client = Groq(api_key=GROQ_API_KEY)

SUPPORTED_SPECIES = ["dog", "cat", "bird", "rabbit"]


# --------------------------------------------------
# SAFE RESPONSE
# --------------------------------------------------

def safe_response(message, status="insufficient_information"):

    return {

        "status": status,

        "answer": message,

        "removed_claims": [],

        "citation_check": {
            "status": "not_completed"
        },

        "sources": []

    }


# --------------------------------------------------
# EXTRACTIVE FALLBACK (no LLM, no invented facts)
# --------------------------------------------------
# If Groq is unavailable or its answer cannot be verified, the answer
# is assembled directly from sentences of the retrieved evidence, each
# with its own citation. This guarantees a grounded, cited answer.

_STOPWORDS = {
    "a", "an", "the", "is", "are", "should", "do", "does", "can", "could",
    "how", "what", "when", "why", "which", "i", "my", "me", "of", "to",
    "for", "and", "or", "in", "on", "it", "its", "often", "much", "many",
    "need", "needs", "have", "has", "be", "s", "pet", "always", "any",
    "suitable", "keep", "maintain"
}

_SPECIFIC_WORDS = re.compile(
    r"\d|\b(daily|weekly|monthly|once|twice|every|per)\b",
    re.IGNORECASE
)

_QUANTITY_QUESTION = re.compile(
    r"\b(how often|how much|how many|how long|how frequently|"
    r"schedule|amount|quantity|portion|times a)\b",
    re.IGNORECASE
)


def _stem(word):

    return re.sub(r"(ing|ed|es|s)$", "", word) if len(word) > 4 else word


def _sentences(text):

    return [
        s.strip()
        for s in re.split(r"(?<=[.!?])\s+", text.strip())
        if s.strip()
    ]


def build_extractive_answer(question, species, pet_name, knowledge):

    clean_question = strip_pet_name(question, species, pet_name)

    terms = {
        w for w in re.findall(r"[a-z]+", clean_question.lower())
        if w not in _STOPWORDS and w != species
    }

    for category in detect_categories(clean_question):
        terms |= CATEGORY_KEYWORDS.get(category, set())

    stems = {_stem(t) for t in terms}

    scored = []

    for ref_index, item in enumerate(knowledge, start=1):

        for position, sentence in enumerate(_sentences(item["content"])):

            words = {
                _stem(w) for w in re.findall(r"[a-z]+", sentence.lower())
            }

            score = len(words & stems)

            if score:
                scored.append((score, ref_index, position, sentence))

    if not scored:
        return None

    best = sorted(scored, key=lambda s: (-s[0], s[1], s[2]))[:4]

    selected = sorted(best, key=lambda s: (s[1], s[2]))

    lines = [f"- {s[3]} [S{s[1]}]" for s in selected]

    if _QUANTITY_QUESTION.search(clean_question) and not any(
        _SPECIFIC_WORDS.search(s[3]) for s in selected
    ):
        lines.append(
            "- The knowledge base does not give a specific amount, "
            "frequency or schedule for this."
        )

    vet_lines = [
        f"- {s[3]} [S{s[1]}]"
        for s in selected
        if re.search(r"veterinar", s[3], re.IGNORECASE)
    ]

    subject = pet_name.strip() if pet_name and pet_name.strip() else f"your {species}"

    first = selected[0]

    answer = "\n".join([
        "## SUMMARY",
        "",
        f"Here is what the knowledge base says that applies to "
        f"{subject}: {first[3]} [S{first[1]}]",
        "",
        "## WHAT YOU SHOULD KNOW",
        "",
        *lines,
        "",
        "## RECOMMENDED ACTIONS",
        "",
        "- Follow the points above. The knowledge base lists no further "
        "specific actions for this question.",
        "",
        "## WHEN TO CONTACT A VET",
        "",
        *(vet_lines or [
            f"- {MISSING_INFO_LINE}",
            f"- If you are concerned about {subject}'s health, consult "
            "a qualified veterinarian."
        ])
    ])

    return answer


def cited_sources(answer, knowledge):

    cited = {int(c) for c in extract_citations(answer)}

    return [

        {

            "reference": f"S{index}",

            "title": item["title"],

            "source": item["source"],

            "url": item["source_url"],

            "similarity": item["similarity"]

        }

        for index, item in enumerate(knowledge, start=1)

        if index in cited

    ]


# --------------------------------------------------
# PET RESPONSE GENERATOR
# --------------------------------------------------

def generate_pet_response(question, species, pet_name=None):

    """
    Generate an evidence-grounded pet-care response.

    1. Validate the species.
    2. Retrieve species-specific knowledge (pet name removed).
    3. Generate an answer from the evidence only.
    4. Validate grounding (line-level, citation-preserving).
    5. If generation or validation fails, return an extractive
       answer built directly from the evidence.
    """

    species = species.lower().strip()

    question = question.strip()

    if not question:

        return safe_response(
            "Please enter a pet-care question."
        )

    if species not in SUPPORTED_SPECIES:

        return safe_response(
            "This pet species is not currently supported."
        )

    # --------------------------------------------------
    # STEP 1: RETRIEVE KNOWLEDGE
    # --------------------------------------------------

    knowledge = retrieve_knowledge(
        query=question,
        species=species,
        top_k=3,
        pet_name=pet_name
    )

    if not knowledge:

        return safe_response(
            "I couldn't find sufficiently relevant information "
            "in the current knowledge base. Please consult a "
            "qualified veterinarian for reliable guidance."
        )

    # --------------------------------------------------
    # STEP 2: PREPARE EVIDENCE
    # --------------------------------------------------

    evidence_sections = []

    for index, item in enumerate(knowledge, start=1):

        evidence_sections.append(

            f"""
[S{index}]

Title: {item['title']}

Species: {item['species']}

Category: {item['category']}

Information:
{item['content']}

Source: {item['source']}

Source URL: {item['source_url']}
"""

        )

    context = "\n".join(evidence_sections)

    # --------------------------------------------------
    # STEP 3: PET DETAILS
    # --------------------------------------------------

    if pet_name and pet_name.strip():

        pet_details = (
            f"The pet's name is {pet_name.strip()}. "
            f"The pet's species is {species}."
        )

    else:

        pet_details = (
            f"The pet's species is {species}. "
            "The pet's name was not provided."
        )

    # --------------------------------------------------
    # STEP 4: GROQ PROMPT
    # --------------------------------------------------

    prompt = f"""

You are PawCare AI, an evidence-grounded pet-care
information assistant inside the PawCart application.

PET SPECIES:
{species}

PET DETAILS:
{pet_details}

USER QUESTION:
{question}

RETRIEVED EVIDENCE:
{context}


STRICT GROUNDING RULES:

1. Use the retrieved evidence as the ONLY source
   for veterinary and pet-care factual claims.

2. Do not use general knowledge from your training
   to add recommendations or veterinary facts.

3. Every factual claim about pet care must end with
   a source reference such as [S1] or [S2].

4. Only cite a source if its actual content supports
   the associated statement.

5. Do not invent food recommendations, quantities,
   feeding schedules, treatments, symptoms or diagnoses.

6. Do not assume that the pet has a medical condition.

7. You may repeat the user's question and pet details,
   but distinguish user-provided information from
   information supported by retrieved evidence.

8. Do not mention retrieval similarity scores.

9. PARTIAL ANSWERS: if the evidence answers only part of
   the question (for example it says water must be available
   but gives no frequency), answer that part with citations
   and then state, in one sentence WITHOUT a citation, what
   the knowledge base does not specify. Do not refuse to
   answer when some relevant evidence exists.

10. For potentially serious health concerns, recommend
    professional veterinary evaluation without
    attempting to diagnose the animal.

11. Do not cite a document merely because it was retrieved.
    Its content must support the specific claim.

12. Do not fabricate source references.

13. Use the pet's name naturally where appropriate.

14. Do not claim to know the pet's age, breed, weight,
    medical history or other details unless supplied.

15. Do not make assumptions about the pet's individual
    nutritional or medical requirements.

16. CITATION FORMAT: write each citation as its own
    bracket, e.g. [S1] [S2]. Never write [S1, S2],
    (S1), "Source 1" or any other format. Statements
    about missing information need no citation.


RESPONSE FORMAT:

## SUMMARY

Give a short, direct answer to the user's question.

## WHAT YOU SHOULD KNOW

Explain only information supported by the retrieved
evidence. Include appropriate source references.

## RECOMMENDED ACTIONS

Provide only actions explicitly supported by the
retrieved evidence.

If there are no supported actions, say so.

## WHEN TO CONTACT A VET

Include only relevant veterinary guidance supported
by the evidence.

If the evidence does not cover this, clearly say that
the knowledge base does not provide specific guidance.

Keep the response friendly, clear and concise.

Use Markdown formatting for headings and lists.

"""

    # --------------------------------------------------
    # STEP 5: GENERATE RESPONSE
    # --------------------------------------------------

    answer = None

    try:

        completion = client.chat.completions.create(

            model=GROQ_MODEL,

            messages=[

                {
                    "role": "system",

                    "content": (
                        "You are a careful veterinary information "
                        "assistant. Evidence grounding is mandatory. "
                        "Never invent facts or citations."
                    )

                },

                {
                    "role": "user",

                    "content": prompt

                }

            ],

            temperature=0.1

        )

        answer = completion.choices[0].message.content

        if not answer or not answer.strip():

            raise ValueError(
                "Groq returned an empty response."
            )

    except Exception as error:

        print("PawCare response generation failed:", error)

        answer = None

    # --------------------------------------------------
    # STEP 6: GROUNDING VALIDATION
    # --------------------------------------------------

    validation = None

    if answer:

        validation = validate_grounding(

            answer=answer,

            knowledge=knowledge

        )

    if validation is None or validation["status"] != "validated":

        # Never leave the user without a grounded answer when the
        # evidence supports something: build it from the evidence.

        fallback = build_extractive_answer(
            question, species, pet_name, knowledge
        )

        if fallback:

            return {

                "status": "success",

                "answer": fallback,

                "removed_claims": (
                    validation["removed_claims"] if validation else []
                ),

                "citation_check": {
                    "status": "passed",
                    "method": "extractive_fallback",
                    "semantic_review": "not_applicable"
                },

                "sources": cited_sources(fallback, knowledge)

            }

        if validation is None:

            return safe_response(
                "PawCare AI could not generate a response just now. "
                "Please try again.",
                status="generation_failed"
            )

        return {

            "status": "validation_failed",

            "answer": validation["answer"],

            "removed_claims": validation.get("removed_claims", []),

            "citation_check": validation.get("citation_check", {}),

            "sources": []

        }

    # --------------------------------------------------
    # STEP 7: PREPARE SOURCES
    # --------------------------------------------------

    return {

        "status": "success",

        "answer": validation["answer"],

        "removed_claims": validation["removed_claims"],

        "citation_check": validation["citation_check"],

        "sources": cited_sources(validation["answer"], knowledge)

    }


# --------------------------------------------------
# TESTING
# --------------------------------------------------

if __name__ == "__main__":

    test_questions = [

        "What should Hazel eat?",

        "How often should Hazel drink water?",

        "Should Hazel have fresh drinking water available?"

    ]

    for question in test_questions:

        print("\n" + "=" * 65)

        print("QUESTION:", question)

        print("=" * 65)

        result = generate_pet_response(

            question=question,

            species="cat",

            pet_name="Hazel"

        )

        print("\nSTATUS:", result["status"])

        print("CITATION CHECK:", result["citation_check"])

        print("\nPAWCARE AI RESPONSE:")

        print(result["answer"])

        print("\nSOURCES:")

        for source in result["sources"]:

            print(source["reference"], "-", source["title"],
                  "-", source["source"])
