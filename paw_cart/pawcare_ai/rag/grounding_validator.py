import json
import re

from groq import Groq

from config import GROQ_API_KEY, GROQ_MODEL


client = Groq(api_key=GROQ_API_KEY)


MISSING_INFO_LINE = (
    "The knowledge base does not provide specific guidance on this."
)

# --------------------------------------------------
# CITATION NORMALISATION
# --------------------------------------------------
# Models write citations in many shapes: [S1, S2], (S1), [Source 1],
# 【S1】. They are all converted to the canonical form "[S1] [S2]"
# BEFORE anything is validated, so a harmless format change can no
# longer make a valid answer look uncited.

_ITEM = r"(?:S|Sources?\s*:?\s*)\s*\d+"
_MORE = r"(?:\s*(?:,|;|and|&)\s*(?:S|Sources?\s*:?\s*)?\s*\d+)*"

_CITATION_GROUP = re.compile(
    r"[\[\(\u3010]\s*(" + _ITEM + _MORE + r")\s*[\]\)\u3011]",
    re.IGNORECASE
)

_CANONICAL = re.compile(r"\[S(\d+)\]")

_INVISIBLE = re.compile(r"[\u200b-\u200f\ufeff]")


def normalize_citations(text):

    def _replace(match):
        numbers = re.findall(r"\d+", match.group(1))
        return " ".join(f"[S{int(n)}]" for n in numbers)

    return _CITATION_GROUP.sub(_replace, _INVISIBLE.sub("", text))


def extract_citations(answer):

    return _CANONICAL.findall(normalize_citations(answer))


def validate_citations(answer, valid_references):

    """True only if the answer cites at least one source and every
    citation refers to a retrieved source."""

    citations = extract_citations(answer)

    if not citations:
        return False

    return all(f"S{c}" in valid_references for c in citations)


# --------------------------------------------------
# LINE HELPERS
# --------------------------------------------------

def is_heading(line):

    stripped = line.strip()

    if stripped.startswith("#"):
        return True

    stripped = stripped.strip("*_ ")

    return bool(
        re.fullmatch(r"[A-Z][A-Z0-9 &/,'\-]{2,}:?", stripped)
    )


def _plain(line):

    return re.sub(r"^[\s>*\-\u2022\d.)]+", "", line).strip()


def _rebuild(entries):

    """Rebuild the answer from (kind, text) entries. A section whose
    content was entirely removed gets an honest 'no guidance' line."""

    output = []

    index = 0

    while index < len(entries):

        kind, text = entries[index]

        if kind != "heading":

            if kind in ("content", "blank"):
                output.append(text)

            index += 1

            continue

        end = index + 1

        while end < len(entries) and entries[end][0] != "heading":
            end += 1

        section = entries[index + 1:end]

        output.append(text)

        has_content = any(k == "content" for k, _ in section)
        has_removed = any(k == "removed" for k, _ in section)

        if has_removed and not has_content:
            output.extend(["", MISSING_INFO_LINE])

        output.extend(t for k, t in section if k in ("content", "blank"))

        index = end

    return re.sub(r"\n{3,}", "\n\n", "\n".join(output)).strip()


# --------------------------------------------------
# LLM AUDIT (does NOT rewrite the answer)
# --------------------------------------------------

def _audit_lines(numbered_lines, evidence):

    """
    Ask the reviewer which numbered lines are unsupported.

    The reviewer only returns line numbers. It never rewrites text, so
    it cannot drop or reformat citations. Returns {line_no: reason},
    or None if the reviewer could not be used.
    """

    listing = "\n".join(
        f"L{number}: {text}" for number, text in numbered_lines
    )

    prompt = f"""
You are a strict evidence auditor for PawCare AI.

RETRIEVED EVIDENCE:
{evidence}

ANSWER LINES:
{listing}

Decide which lines must be REMOVED.

REMOVE a line only if it states a pet-care or veterinary fact,
quantity, schedule, treatment or diagnosis that the evidence does not
support, or if its citation points to a source that does not support it.

KEEP a line if it is supported by the cited source, restates the owner's
question or pet details, says that the knowledge base lacks information,
or gives generic advice to consult a veterinarian.

Do NOT rewrite, merge or edit any line.

Return ONLY valid JSON without Markdown fences:

{{"remove": [{{"line": 3, "reason": "short reason"}}]}}

If nothing must be removed return {{"remove": []}}.
"""

    try:

        completion = client.chat.completions.create(

            model=GROQ_MODEL,

            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a strict evidence verification "
                        "assistant. Never invent veterinary facts."
                    )
                },
                {"role": "user", "content": prompt}
            ],

            temperature=0

        )

        raw = completion.choices[0].message.content or ""

        start, end = raw.find("{"), raw.rfind("}")

        if start == -1 or end == -1:
            raise ValueError("Invalid auditor JSON.")

        data = json.loads(raw[start:end + 1])

        valid_numbers = {number for number, _ in numbered_lines}

        removals = {}

        for item in data.get("remove", []):

            if isinstance(item, dict):
                number, reason = item.get("line"), item.get("reason", "")
            else:
                number, reason = item, ""

            try:
                number = int(number)
            except (TypeError, ValueError):
                continue

            if number in valid_numbers:
                removals[number] = str(reason)

        return removals

    except Exception as error:

        print("Grounding audit unavailable:", error)

        return None


# --------------------------------------------------
# GROUNDING VALIDATION
# --------------------------------------------------

def validation_failure(message, removed_claims=None):

    return {
        "status": "validation_failed",
        "answer": message,
        "removed_claims": removed_claims or [],
        "citation_check": {
            "status": "failed"
        }
    }


def validate_grounding(answer, knowledge):

    """
    1. Normalise citation formats.
    2. Strip citations that do not exist; drop lines supported only by
       such invented citations.
    3. Let the auditor flag unsupported lines (line numbers only).
    4. Remove exactly those lines from the ORIGINAL text, so surviving
       lines keep their wording and citations.
    5. Pass only if at least one valid citation remains.
    """

    if not knowledge:

        return {
            "status": "insufficient_information",
            "answer": (
                "There is not enough verified information in "
                "the current knowledge base to answer this question."
            ),
            "removed_claims": [],
            "citation_check": {
                "status": "not_applicable"
            }
        }

    valid_references = set()

    evidence_sections = []

    for index, item in enumerate(knowledge, start=1):

        reference = f"S{index}"

        valid_references.add(reference)

        evidence_sections.append(
            f"[{reference}]\n"
            f"Title: {item['title']}\n"
            f"Species: {item['species']}\n"
            f"Category: {item['category']}\n"
            f"Content: {item['content']}\n"
            f"Source: {item['source']}\n"
        )

    evidence = "\n".join(evidence_sections)

    removed_claims = []

    entries = []

    for line in normalize_citations(answer).split("\n"):

        if not line.strip():
            entries.append(("blank", ""))
            continue

        if is_heading(line):
            entries.append(("heading", line))
            continue

        refs = _CANONICAL.findall(line)

        if any(f"S{r}" not in valid_references for r in refs):

            cleaned = _CANONICAL.sub(
                lambda m: m.group(0)
                if f"S{m.group(1)}" in valid_references else "",
                line
            )

            cleaned = re.sub(r"[ \t]{2,}", " ", cleaned).rstrip()

            if not _CANONICAL.search(cleaned):

                # Its only support was a fabricated citation.
                removed_claims.append(_plain(line))
                entries.append(("removed", line))
                continue

            line = cleaned

        entries.append(("content", line))

    content_positions = [
        i for i, (kind, _) in enumerate(entries) if kind == "content"
    ]

    numbered = [
        (number, entries[position][1])
        for number, position in enumerate(content_positions, start=1)
    ]

    semantic_review = "not_completed"

    if numbered:

        removals = _audit_lines(numbered, evidence)

        if removals is not None:

            semantic_review = "completed"

            for number in removals:

                position = content_positions[number - 1]

                removed_claims.append(_plain(entries[position][1]))

                entries[position] = ("removed", entries[position][1])

    final_answer = _rebuild(entries)

    if not validate_citations(final_answer, valid_references):

        print("Grounding validation: no valid citation remains.")

        return validation_failure(
            "PawCare AI could not verify this response. "
            "Please try again or consult a qualified veterinarian.",
            removed_claims
        )

    return {
        "status": "validated",
        "answer": final_answer,
        "removed_claims": removed_claims,
        "citation_check": {
            "status": (
                "passed" if semantic_review == "completed"
                else "reference_check_only"
            ),
            "method": "line_level_audit",
            "semantic_review": semantic_review
        }
    }


if __name__ == "__main__":

    sample_knowledge = [
        {
            "title": "Basic cat nutrition",
            "species": "cat",
            "category": "nutrition",
            "content": (
                "Cats require a complete and balanced diet. "
                "Fresh drinking water should always be available."
            ),
            "source": "Merck Veterinary Manual",
            "source_url": "https://www.merckvetmanual.com/"
        }
    ]

    sample_answer = """
## SUMMARY

Cats need a complete and balanced diet (S1).
"""

    print(json.dumps(
        validate_grounding(sample_answer, sample_knowledge), indent=4
    ))
