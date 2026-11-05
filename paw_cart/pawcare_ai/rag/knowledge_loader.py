
import json
from pathlib import Path

import chromadb
from sentence_transformers import SentenceTransformer


BASE_DIR = Path(__file__).resolve().parent.parent
KNOWLEDGE_FILE = BASE_DIR / "knowledge_base" / "pet_care_knowledge.json"
DATABASE_DIR = BASE_DIR / "chroma_db"

EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

print("Loading embedding model...")
embedding_model = SentenceTransformer(EMBEDDING_MODEL)

client = chromadb.PersistentClient(path=str(DATABASE_DIR))

collection = client.get_or_create_collection(
    name="pawcare_knowledge",
    metadata={"hnsw:space": "cosine"}
)


def load_knowledge():
    with open(KNOWLEDGE_FILE, "r", encoding="utf-8") as file:
        documents = json.load(file)

    return documents


def ingest_knowledge():
    documents = load_knowledge()

    for document in documents:
        text = (
            f"Title: {document['title']}\n"
            f"Species: {document['species']}\n"
            f"Category: {document['category']}\n"
            f"Content: {document['content']}"
        )

        embedding = embedding_model.encode(text).tolist()

        collection.upsert(
            ids=[document["id"]],
            documents=[text],
            embeddings=[embedding],
            metadatas=[{
                "species": document["species"],
                "category": document["category"],
                "title": document["title"],
                "source": document["source"],
                "source_url": document["source_url"]
            }]
        )

    print(f"Successfully indexed {len(documents)} documents!")
    print(f"Total documents in database: {collection.count()}")


if __name__ == "__main__":
    ingest_knowledge()
