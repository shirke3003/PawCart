import re
import chromadb

from pathlib import Path
from sentence_transformers import SentenceTransformer


# --------------------------------------------------
# PATHS AND CONFIGURATION
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
DATABASE_DIR = BASE_DIR / "chroma_db"

EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

SUPPORTED_SPECIES = ["dog", "cat", "bird", "rabbit"]

# Applied when no care category could be detected.
SIMILARITY_THRESHOLD = 0.35

# Applied to documents whose metadata category already matches the
# detected category (species + category agreement is strong evidence,
# so a short question does not also need a high embedding score).
CATEGORY_MATCH_THRESHOLD = 0.15

print("Initializing PawCare retriever...")

embedding_model = SentenceTransformer(EMBEDDING_MODEL)

client = chromadb.PersistentClient(
    path=str(DATABASE_DIR)
)

collection = client.get_collection(
    name="pawcare_knowledge"
)

# similarity = 1 - distance is only valid for cosine distance.
_space = (collection.metadata or {}).get("hnsw:space", "l2")

if _space != "cosine":
    print(
        "WARNING: the ChromaDB collection is not using cosine distance "
        f"(found '{_space}'). Delete the chroma_db folder and re-run "
        "rag/knowledge_loader.py so similarity scores are valid."
    )


# --------------------------------------------------
# CATEGORY KEYWORDS
# --------------------------------------------------

CATEGORY_KEYWORDS = {

    "hydration": {
        "water", "drink", "drinks", "drinking", "hydration",
        "hydrated", "hydrate", "hydrating", "thirst", "thirsty",
        "fluid", "fluids", "dehydration", "dehydrated", "intake"
    },

    "nutrition": {
        "feed", "fed", "food", "foods", "diet", "dietary", "eat",
        "ate", "eating", "nutrition", "nutritional", "meal", "meals",
        "feeding", "hay", "treat", "treats", "kibble", "pellets",
        "greens", "vegetables", "fruit", "fruits"
    },

    "hygiene": {
        "hygiene", "litter", "toilet", "clean", "cleaned", "cleaning",
        "waste", "sanitation", "bath", "bathing"
    },

    "exercise": {
        "exercise", "exercises", "exercising", "activity", "activities",
        "active", "play", "playing", "toy", "toys", "enrichment",
        "walk", "walks", "walking"
    },

    "environment": {
        "cage", "cages", "enclosure", "enclosures", "housing",
        "habitat", "environment", "home", "temperature",
        "ventilation", "perch", "perches", "shelter"
    },

    "health_and_grooming": {
        "groom", "grooming", "groomed", "brush", "brushing",
        "checkup", "checkups", "health", "coat", "fur", "vet",
        "veterinary"
    },

    "behaviour": {
        "behaviour", "behavior", "screaming", "biting", "boredom",
        "bored", "feather", "plucking", "mental", "mentally",
        "stimulation", "stimulated", "foraging", "social",
        "interaction", "training"
    }
}


# --------------------------------------------------
# CATEGORY TO DATABASE MAPPING
# --------------------------------------------------

CATEGORY_MAPPING = {

    "hydration": ["nutrition"],

    "nutrition": ["nutrition"],

    "hygiene": ["hygiene", "health_and_grooming"],

    "exercise": [
        "exercise",
        "exercise_and_environment",
        "exercise_and_enrichment",
        "behaviour_and_enrichment"
    ],

    "environment": ["environment", "exercise_and_environment"],

    "health_and_grooming": ["health_and_grooming"],

    "behaviour": [
        "behaviour_and_enrichment",
        "exercise_and_enrichment"
    ]
}

# Water facts are stored under "nutrition". For a hydration-only
# question, only nutrition documents that actually mention water
# may be used as evidence.
CONTENT_REQUIREMENTS = {
    "hydration": ("water", "drink", "hydrat", "fluid")
}


# --------------------------------------------------
# QUERY EXPANSIONS
# --------------------------------------------------

CATEGORY_EXPANSIONS = {

    "hydration": (
        "fresh drinking water, continuous access to water, "
        "water availability, pet hydration and drinking habits"
    ),

    "nutrition": (
        "complete and balanced diet, pet food, feeding, "
        "dietary requirements and nutritional needs"
    ),

    "hygiene": (
        "cleanliness, sanitation, hygiene and waste management"
    ),

    "exercise": (
        "physical activity, exercise requirements, play "
        "and enrichment"
    ),

    "environment": (
        "safe housing, habitat, enclosure and living environment"
    ),

    "health_and_grooming": (
        "routine care, grooming, coat care and veterinary checkups"
    ),

    "behaviour": (
        "animal behaviour, mental stimulation, social interaction "
        "and enrichment"
    )
}


# --------------------------------------------------
# PET NAME HANDLING
# --------------------------------------------------

def strip_pet_name(query, species, pet_name=None):

    """
    Replace the pet's name with 'my <species>'.

    A name such as 'Hazel' carries no pet-care meaning, but it shifts
    the embedding and can collide with category keywords (a pet called
    'Hay' or 'Coat'). Replacing it keeps retrieval and category
    detection about the question itself.
    """

    if not pet_name or not pet_name.strip():
        return query

    pattern = re.compile(
        rf"(?<!\w){re.escape(pet_name.strip())}(?P<poss>['\u2019]s)?(?!\w)",
        re.IGNORECASE
    )

    return pattern.sub(
        lambda m: f"my {species}" + ("'s" if m.group("poss") else ""),
        query
    )


# --------------------------------------------------
# CATEGORY DETECTION
# --------------------------------------------------

def detect_categories(query):

    """
    Return every category tied for the highest keyword score.

    Scoring (instead of first-match-wins) stops a question such as
    "How should I clean my bird's water bowl?" being forced into
    whichever category happens to be listed first.
    """

    words = set(re.findall(r"[a-z]+", query.lower()))

    scores = {

        category: len(words & keywords)

        for category, keywords in CATEGORY_KEYWORDS.items()

    }

    best = max(scores.values())

    if best == 0:
        return []

    return [c for c, s in scores.items() if s == best]


def detect_category(query):

    """Single best category (kept for compatibility)."""

    categories = detect_categories(query)

    return categories[0] if categories else None


# --------------------------------------------------
# SPECIES-AWARE QUERY NORMALIZATION
# --------------------------------------------------

def normalize_query(query, species, category=None):

    """
    Expand the question with species and category context.
    'category' may be a single category, a list, or None.
    """

    species = species.lower().strip()

    normalized_query = (
        f"{query}. "
        f"This question is about a {species}. "
        f"Pet species: {species}."
    )

    if isinstance(category, str):
        category = [category]

    for item in category or []:

        expansion = CATEGORY_EXPANSIONS.get(item, "")

        if expansion:

            normalized_query += (
                f" Relevant {species} {item} information: "
                f"{expansion}."
            )

    return normalized_query


def _extract_content(document):

    """
    The loader stores 'Title/Species/Category/Content:' text in
    ChromaDB. Return only the original content so the evidence given
    to Groq and the validator is clean.
    """

    if "Content:" in document:
        return document.split("Content:", 1)[1].strip()

    return document.strip()


# --------------------------------------------------
# KNOWLEDGE RETRIEVAL
# --------------------------------------------------

def retrieve_knowledge(
    query,
    species,
    top_k=3,
    pet_name=None,
    use_category_filter=True
):

    """
    Retrieve relevant pet-care information.

    1. Remove the pet's name from the question.
    2. Detect the care category (optional).
    3. Embed the species-aware query and search ChromaDB.
    4. Keep documents of the matching category / above threshold.
    5. Return the most similar documents.

    No unrelated documents are returned as a fallback.
    """

    species = species.lower().strip()

    if species not in SUPPORTED_SPECIES:
        return []

    if collection.count() == 0:
        return []

    species_total = len(
        collection.get(where={"species": species}, include=[])["ids"]
    )

    if species_total == 0:
        return []

    clean_query = strip_pet_name(query, species, pet_name)

    categories = (
        detect_categories(clean_query) if use_category_filter else []
    )

    retrieval_query = normalize_query(clean_query, species, categories)

    query_embedding = embedding_model.encode(retrieval_query).tolist()

    candidate_limit = min(max(top_k * 4, 10), species_total)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=candidate_limit,
        where={"species": species},
        include=["documents", "metadatas", "distances"]
    )

    if not results["documents"] or not results["documents"][0]:
        return []

    relevant_categories = set()

    for category in categories:
        relevant_categories.update(CATEGORY_MAPPING.get(category, []))

    required_terms = ()

    if "hydration" in categories and "nutrition" not in categories:
        required_terms = CONTENT_REQUIREMENTS["hydration"]

    threshold = (
        CATEGORY_MATCH_THRESHOLD if categories else SIMILARITY_THRESHOLD
    )

    retrieved_documents = []

    for i, document in enumerate(results["documents"][0]):

        metadata = results["metadatas"][0][i]

        similarity = 1 - results["distances"][0][i]

        content = _extract_content(document)

        category = metadata.get("category", "general")

        if categories and category not in relevant_categories:
            continue

        if similarity < threshold:
            continue

        if required_terms and not any(
            term in content.lower() for term in required_terms
        ):
            continue

        retrieved_documents.append({

            "content": content,

            "title": metadata.get("title", "Untitled document"),

            "species": metadata.get("species", species),

            "category": category,

            "source": metadata.get("source", "Unknown source"),

            "source_url": metadata.get("source_url", ""),

            "similarity": round(similarity, 4)

        })

    retrieved_documents.sort(
        key=lambda doc: doc["similarity"],
        reverse=True
    )

    return retrieved_documents[:top_k]


# --------------------------------------------------
# RETRIEVER TESTING
# --------------------------------------------------

if __name__ == "__main__":

    test_questions = [

        {"question": "What should Hazel eat?", "species": "cat", "pet_name": "Hazel"},
        {"question": "What should I feed my cat?", "species": "cat"},
        {"question": "Should Hazel have fresh drinking water available?", "species": "cat", "pet_name": "Hazel"},
        {"question": "How often should Hazel drink water?", "species": "cat", "pet_name": "Hazel"},
        {"question": "How do I maintain my cat's litter box?", "species": "cat"},
        {"question": "What should my dog eat?", "species": "dog"},
        {"question": "Should my dog always have drinking water?", "species": "dog"},
        {"question": "How much exercise does my dog need?", "species": "dog"},
        {"question": "What food is suitable for my rabbit?", "species": "rabbit"},
        {"question": "How can I keep my rabbit hydrated?", "species": "rabbit"},
        {"question": "How should I maintain my bird's enclosure?", "species": "bird"},
        {"question": "How can I keep my pet bird mentally stimulated?", "species": "bird"}

    ]

    for test in test_questions:

        clean = strip_pet_name(
            test["question"], test["species"], test.get("pet_name")
        )

        print("\n" + "=" * 65)
        print("QUESTION:", test["question"])
        print("SPECIES:", test["species"])
        print("CLEANED:", clean)
        print("DETECTED CATEGORIES:", detect_categories(clean))
        print("=" * 65)

        results = retrieve_knowledge(
            query=test["question"],
            species=test["species"],
            top_k=3,
            pet_name=test.get("pet_name")
        )

        if not results:
            print("No sufficiently relevant documents found.")
            continue

        for result in results:
            print("\nTitle:", result["title"])
            print("Category:", result["category"])
            print("Similarity:", result["similarity"])
            print("Source:", result["source"])
            print("-" * 50)
