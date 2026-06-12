import re
import unicodedata
from dataclasses import dataclass

from fastapi import APIRouter

from app import schemas

router = APIRouter(prefix="/food-filter", tags=["food-filter"])


FOOD_CATEGORIES = {
    "alimentaire",
    "alimentation",
    "boisson",
    "boissons",
    "boucherie",
    "boulangerie",
    "charcuterie",
    "cremerie",
    "epicerie",
    "fromage",
    "fruit",
    "fruits",
    "legume",
    "legumes",
    "poissonnerie",
    "produit frais",
    "produits frais",
    "surgeles",
    "viande",
}

NON_FOOD_CATEGORIES = {
    "animalerie",
    "beaute",
    "bricolage",
    "electromenager",
    "hygiene",
    "jardin",
    "maison",
    "menage",
    "papeterie",
    "pharmacie",
    "textile",
}

FOOD_TERMS = {
    "abricot",
    "ail",
    "agneau",
    "amande",
    "ananas",
    "avocat",
    "banane",
    "biscuit",
    "beurre",
    "biere",
    "brioche",
    "boeuf",
    "bonbon",
    "brocoli",
    "cafe",
    "carotte",
    "cereale",
    "cerise",
    "champignon",
    "chips",
    "chocolat",
    "citron",
    "concombre",
    "cookie",
    "courgette",
    "creme",
    "croissant",
    "dessert",
    "dinde",
    "eau",
    "emmental",
    "farine",
    "fraise",
    "fromage",
    "glace",
    "haricot",
    "huile",
    "jambon",
    "jus",
    "kiwi",
    "laitue",
    "lait",
    "lardon",
    "lentille",
    "maquereau",
    "mangue",
    "miel",
    "mozzarella",
    "muesli",
    "noix",
    "nouille",
    "oeuf",
    "oignon",
    "orange",
    "pamplemousse",
    "pain",
    "pate",
    "pates",
    "patisserie",
    "peche",
    "petit pois",
    "poire",
    "poireau",
    "poisson",
    "poivron",
    "poivre",
    "pomme",
    "pomme de terre",
    "porc",
    "poulet",
    "radis",
    "raisin",
    "riz",
    "salade",
    "saumon",
    "sel",
    "semoule",
    "soda",
    "soupe",
    "steak",
    "thon",
    "sucre",
    "the",
    "tomate",
    "tortilla",
    "veau",
    "vin",
    "yaourt",
}

NON_FOOD_TERMS = {
    "adoucissant",
    "ampoule",
    "assiette",
    "balai",
    "batterie",
    "bougie",
    "brosse",
    "cahier",
    "chargeur",
    "dentifrice",
    "deodorant",
    "eponge",
    "javel",
    "lessive",
    "lingette",
    "mouchoir",
    "papier",
    "parfum",
    "pile",
    "poubelle",
    "rasoir",
    "savon",
    "serviette",
    "shampoing",
    "sopalin",
    "stylo",
    "toilette",
    "vaisselle",
}


@dataclass
class NormalizedItem:
    name: str
    quantity: str
    category: str


def normalize_text(value: str | None) -> str:
    text = unicodedata.normalize("NFKD", str(value or "").lower())
    text = "".join(char for char in text if not unicodedata.combining(char))
    return re.sub(r"[^a-z0-9]+", " ", text).strip()


def tokenize(value: str) -> set[str]:
    tokens: set[str] = set()
    for token in normalize_text(value).split():
        if len(token) <= 1:
            continue
        tokens.add(token)
        if len(token) > 3 and token.endswith(("s", "x")):
            tokens.add(token[:-1])
    return tokens


def normalize_item(raw_item: str | schemas.ShoppingListItem) -> NormalizedItem:
    if isinstance(raw_item, str):
        return NormalizedItem(name=raw_item.strip(), quantity="", category="")
    return NormalizedItem(
        name=raw_item.name.strip(),
        quantity=(raw_item.quantity or "").strip(),
        category=(raw_item.category or "").strip(),
    )


def find_matches(tokens: set[str], terms: set[str]) -> list[str]:
    matches = set(tokens.intersection(terms))
    matches.update(term for term in terms if " " in term and set(term.split()).issubset(tokens))
    return sorted(matches)


def is_food_category(category: str) -> bool:
    normalized = normalize_text(category)
    return any(food_category in normalized for food_category in FOOD_CATEGORIES)


def is_non_food_category(category: str) -> bool:
    normalized = normalize_text(category)
    return any(non_food_category in normalized for non_food_category in NON_FOOD_CATEGORIES)


def classify_item(item: NormalizedItem) -> tuple[bool, float, list[str], str]:
    tokens = tokenize(item.name)
    food_matches = find_matches(tokens, FOOD_TERMS)
    non_food_matches = find_matches(tokens, NON_FOOD_TERMS)

    if item.category and is_food_category(item.category):
        confidence = 0.95 if food_matches else 0.85
        return True, confidence, food_matches, ""

    if item.category and is_non_food_category(item.category):
        return False, 0.0, non_food_matches, "Categorie non alimentaire"

    if food_matches and not non_food_matches:
        confidence = min(0.98, 0.65 + len(food_matches) * 0.1)
        return True, confidence, food_matches, ""

    if food_matches and len(food_matches) > len(non_food_matches):
        return True, 0.7, food_matches, ""

    if non_food_matches:
        return False, 0.0, non_food_matches, "Produit non alimentaire detecte"

    return False, 0.0, [], "Impossible de confirmer que le produit est alimentaire"


@router.post("/filter", response_model=schemas.FoodFilterResponse)
def filter_food_items(payload: schemas.FoodFilterRequest) -> schemas.FoodFilterResponse:
    food_items: list[schemas.FoodFilterItemPublic] = []
    rejected_items: list[schemas.FoodFilterRejectedItemPublic] = []

    for raw_item in payload.items:
        item = normalize_item(raw_item)
        is_food, confidence, matched_terms, reason = classify_item(item)

        if is_food:
            food_items.append(
                schemas.FoodFilterItemPublic(
                    name=item.name,
                    quantity=item.quantity,
                    category=item.category or "Alimentaire",
                    confidence=round(confidence, 2),
                    matchedTerms=matched_terms,
                )
            )
            continue

        rejected_items.append(
            schemas.FoodFilterRejectedItemPublic(
                name=item.name,
                quantity=item.quantity,
                category=item.category,
                reason=reason,
                matchedTerms=matched_terms,
            )
        )

    return schemas.FoodFilterResponse(
        foodItems=food_items,
        rejectedItems=rejected_items,
        totalItems=len(payload.items),
        foodCount=len(food_items),
        rejectedCount=len(rejected_items),
    )
