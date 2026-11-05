
ASSESSMENT_QUESTIONS = {
    "dog": [
        {
            "id": "diet",
            "question": "What type of food does your dog usually eat?",
            "options": [
                "Commercial dog food",
                "Homemade food",
                "A combination of both",
                "Other / Not sure"
            ]
        },
        {
            "id": "water",
            "question": "How is your dog's access to drinking water?",
            "options": [
                "Fresh water available throughout the day",
                "Water provided at specific times",
                "Not sure"
            ]
        },
        {
            "id": "activity",
            "question": "How active is your dog on a typical day?",
            "options": [
                "Very active",
                "Moderately active",
                "Mostly inactive",
                "Not sure"
            ]
        },
        {
            "id": "grooming",
            "question": "How often is your dog groomed?",
            "options": [
                "Daily",
                "Several times a week",
                "Occasionally",
                "Rarely"
            ]
        },
        {
            "id": "concern",
            "question": "What is your primary concern about your dog's care?",
            "options": [
                "Nutrition and diet",
                "Exercise and activity",
                "Grooming and hygiene",
                "General health",
                "No particular concern"
            ]
        }
    ],

    "cat": [
        {
            "id": "diet",
            "question": "What does your cat usually eat?",
            "options": [
                "Commercial cat food",
                "Homemade food",
                "A combination of both",
                "Other / Not sure"
            ]
        },
        {
            "id": "water",
            "question": "How does your cat receive drinking water?",
            "options": [
                "Fresh water available throughout the day",
                "Water provided at specific times",
                "Not sure"
            ]
        },
        {
            "id": "litter",
            "question": "How often is your cat's litter box cleaned?",
            "options": [
                "Daily",
                "Every few days",
                "Occasionally",
                "Not applicable"
            ]
        },
        {
            "id": "grooming",
            "question": "How often is your cat groomed?",
            "options": [
                "Daily",
                "Several times a week",
                "Occasionally",
                "Rarely"
            ]
        },
        {
            "id": "concern",
            "question": "What is your primary concern about your cat's care?",
            "options": [
                "Nutrition and diet",
                "Hydration",
                "Grooming and hygiene",
                "General health",
                "No particular concern"
            ]
        }
    ],

    "bird": [
        {
            "id": "diet",
            "question": "What does your bird usually eat?",
            "options": [
                "Formulated pellets or crumbles",
                "Seeds and grains",
                "Fresh fruits and vegetables",
                "A combination of these",
                "Other / Not sure"
            ]
        },
        {
            "id": "water",
            "question": "How often are your bird's water containers cleaned?",
            "options": [
                "Daily",
                "Every few days",
                "Occasionally",
                "Not sure"
            ]
        },
        {
            "id": "environment",
            "question": "How would you describe your bird's enclosure?",
            "options": [
                "Spacious with suitable perches",
                "Adequate but limited space",
                "Small enclosure",
                "Not sure"
            ]
        },
        {
            "id": "enrichment",
            "question": "Does your bird have toys or enrichment activities?",
            "options": [
                "Yes, regularly",
                "Sometimes",
                "Rarely",
                "No"
            ]
        },
        {
            "id": "concern",
            "question": "What is your primary concern about your bird's care?",
            "options": [
                "Nutrition and diet",
                "Enclosure and environment",
                "Exercise and enrichment",
                "General health",
                "No particular concern"
            ]
        }
    ],

    "rabbit": [
        {
            "id": "diet",
            "question": "How often does your rabbit have access to grass hay?",
            "options": [
                "Available throughout the day",
                "Provided once or twice a day",
                "Occasionally",
                "Not provided"
            ]
        },
        {
            "id": "food",
            "question": "What else is included in your rabbit's diet?",
            "options": [
                "Suitable rabbit pellets and leafy greens",
                "Mainly pellets",
                "Mainly vegetables",
                "Other / Not sure"
            ]
        },
        {
            "id": "water",
            "question": "How does your rabbit receive drinking water?",
            "options": [
                "Fresh water available throughout the day",
                "Water provided at specific times",
                "Not sure"
            ]
        },
        {
            "id": "activity",
            "question": "How much space does your rabbit have for exercise?",
            "options": [
                "Regular access to a spacious exercise area",
                "Some supervised exercise time",
                "Mostly stays in its enclosure",
                "Not sure"
            ]
        },
        {
            "id": "concern",
            "question": "What is your primary concern about your rabbit's care?",
            "options": [
                "Nutrition and diet",
                "Exercise and housing",
                "Hygiene",
                "General health",
                "No particular concern"
            ]
        }
    ]
}


def get_assessment_questions(species):
    species = species.lower().strip()

    if species not in ASSESSMENT_QUESTIONS:
        return None

    return ASSESSMENT_QUESTIONS[species]
