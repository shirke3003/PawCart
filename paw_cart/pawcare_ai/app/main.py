
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from pydantic import BaseModel, Field

from app.assessment_questions import get_assessment_questions

from rag.response_generator import generate_pet_response

from rag.assessment_generator import generate_assessment


# --------------------------------------------------
# FASTAPI APPLICATION
# --------------------------------------------------

app = FastAPI(

    title="PawCare AI",

    description="RAG-powered pet care assistant for PawCart",

    version="1.0.0"

)


# --------------------------------------------------
# CORS CONFIGURATION
# --------------------------------------------------

app.add_middleware(

    CORSMiddleware,

    allow_origins=["*"],

    allow_credentials=True,

    allow_methods=["*"],

    allow_headers=["*"],

)


# --------------------------------------------------
# SUPPORTED SPECIES
# --------------------------------------------------

ALLOWED_SPECIES = [

    "dog",

    "cat",

    "bird",

    "rabbit"

]


# --------------------------------------------------
# REQUEST MODELS
# --------------------------------------------------

class ChatRequest(BaseModel):

    question: str = Field(
        min_length=3,
        max_length=2000
    )

    species: str

    pet_name: str | None = None


class AssessmentRequest(BaseModel):

    species: str

    pet_name: str | None = None

    answers: dict[str, str]


# --------------------------------------------------
# CHAT API
# --------------------------------------------------

@app.post("/api/chat")
def chat(request: ChatRequest):

    species = request.species.lower().strip()

    question = request.question.strip()

    if species not in ALLOWED_SPECIES:

        raise HTTPException(

            status_code=400,

            detail="Unsupported pet species."

        )

    if not question:

        raise HTTPException(

            status_code=400,

            detail="Please enter a pet-care question."

        )

    result = generate_pet_response(

        question=question,

        species=species,

        pet_name=request.pet_name

    )

    return result


# --------------------------------------------------
# ASSESSMENT QUESTIONS API
# --------------------------------------------------

@app.get("/api/assessment/questions/{species}")
def assessment_questions(species: str):

    species = species.lower().strip()

    questions = get_assessment_questions(species)

    if questions is None:

        raise HTTPException(

            status_code=400,

            detail="Unsupported pet species."

        )

    return {

        "species": species,

        "questions": questions

    }


# --------------------------------------------------
# PET ASSESSMENT API
# --------------------------------------------------

@app.post("/api/assessment")
def pet_assessment(request: AssessmentRequest):

    species = request.species.lower().strip()

    if species not in ALLOWED_SPECIES:

        raise HTTPException(

            status_code=400,

            detail="Unsupported pet species."

        )

    questions = get_assessment_questions(species)

    if questions is None:

        raise HTTPException(

            status_code=400,

            detail="Unsupported pet species."

        )

    # --------------------------------------------------
    # VALIDATE QUESTION IDs
    # --------------------------------------------------

    question_map = {

        question["id"]: question

        for question in questions

    }

    for question_id, answer in request.answers.items():

        if question_id not in question_map:

            raise HTTPException(

                status_code=400,

                detail=f"Invalid question ID: {question_id}"

            )

        # --------------------------------------------------
        # VALIDATE SELECTED OPTIONS
        # --------------------------------------------------

        if answer not in question_map[question_id]["options"]:

            raise HTTPException(

                status_code=400,

                detail=f"Invalid answer for question: {question_id}"

            )

    # --------------------------------------------------
    # GENERATE ASSESSMENT
    # --------------------------------------------------

    result = generate_assessment(

        species=species,

        pet_name=request.pet_name,

        answers=request.answers

    )

    return result


# --------------------------------------------------
# ROOT ENDPOINT
# --------------------------------------------------

@app.get("/")
def home():

    return {

        "message": "Welcome to PawCare AI!",

        "status": "running"

    }


# --------------------------------------------------
# HEALTH CHECK
# --------------------------------------------------

@app.get("/api/health")
def health():

    return {

        "status": "healthy"

    }
