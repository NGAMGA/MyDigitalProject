import json
import re
import unicodedata
from functools import lru_cache
from urllib.request import Request, urlopen

THE_MEAL_DB_INGREDIENTS_URL = "https://www.themealdb.com/api/json/v1/1/list.php?i=list"

_word_splitter = re.compile(r"[^a-z0-9]+")

_fallback_food_terms = {
    "agneau",
    "ail",
    "ananas",
    "aubergine",
    "avocat",
    "banane",
    "beurre",
    "boeuf",
    "carotte",
    "cereales",
    "champignon",
    "cheddar",
    "chevre",
    "chocolat",
    "citron",
    "concombre",
    "courgette",
    "creme",
    "dinde",
    "emmental",
    "farine",
    "fraise",
    "fromage",
    "huile",
    "jambon",
    "lait",
    "lardon",
    "lentille",
    "maïs",
    "mangue",
    "miel",
    "mozzarella",
    "oeuf",
    "oignon",
    "orange",
    "pain",
    "parmesan",
    "pates",
    "peche",
    "poire",
    "poireau",
    "pois",
    "poisson",
    "poivron",
    "pomme",
    "porc",
    "poulet",
    "quinoa",
    "riz",
    "salade",
    "saumon",
    "sel",
    "sucre",
    "thon",
    "tomate",
    "yaourt",
}

_french_aliases = {
    "agneau": "lamb",
    "ail": "garlic",
    "aubergine": "eggplant",
    "avocat": "avocado",
    "banane": "banana",
    "boeuf": "beef",
    "carotte": "carrot",
    "champignon": "mushroom",
    "citron": "lemon",
    "concombre": "cucumber",
    "courgette": "zucchini",
    "creme": "cream",
    "dinde": "turkey",
    "farine": "flour",
    "fraise": "strawberry",
    "fromage": "cheese",
    "huile": "oil",
    "jambon": "ham",
    "lait": "milk",
    "lentille": "lentils",
    "miel": "honey",
    "oeuf": "egg",
    "oignon": "onion",
    "pain": "bread",
    "pates": "pasta",
    "poireau": "leek",
    "poisson": "fish",
    "poivron": "pepper",
    "pomme": "apple",
    "porc": "pork",
    "poulet": "chicken",
    "riz": "rice",
    "salade": "lettuce",
    "saumon": "salmon",
    "thon": "tuna",
    "tomate": "tomato",
    "yaourt": "yogurt",
}

_food_corrections = {
    "petit poids": "Petits pois",
    "petits poids": "Petits pois",
    "petit poid": "Petits pois",
    "petits poid": "Petits pois",
    "petit pois": "Petits pois",
    "pattes": "Pates",
    "pate": "Pates",
    "pates complete": "Pates completes",
    "pates semi complete": "Pates semi-completes",
    "riz basmatti": "Riz basmati",
    "tomattes": "Tomates",
    "pouller": "Poulet",
    "poulet filet": "Filets de poulet",
}


def classify_food_items(items: list[str]) -> tuple[list[str], list[str]]:
    accepted: list[str] = []
    rejected: list[str] = []
    seen: set[str] = set()

    for item in items:
        cleaned = _correct_food_name(_display_name(item))
        normalized = normalize_food_text(cleaned)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)

        if is_food_item(cleaned):
            accepted.append(cleaned)
        else:
            rejected.append(cleaned)

    return accepted, rejected


def is_food_item(value: str) -> bool:
    normalized = normalize_food_text(value)
    corrected = _food_corrections.get(normalized)
    if corrected:
        normalized = normalize_food_text(corrected)
    if len(normalized) < 2:
        return False

    terms = _food_terms()
    if normalized in terms:
        return True

    singular = _singularize(normalized)
    if singular in terms:
        return True

    tokens = [token for token in _word_splitter.split(normalized) if token]
    for token in tokens:
        if token in terms or _singularize(token) in terms:
            return True

    return any(
        f" {term} " in f" {normalized} "
        for term in terms
        if len(term) >= 4 and " " not in term
    )


def normalize_food_text(value: str) -> str:
    no_accents = unicodedata.normalize("NFKD", value)
    ascii_text = "".join(char for char in no_accents if not unicodedata.combining(char))
    lowered = ascii_text.lower()
    normalized = _word_splitter.sub(" ", lowered)
    return " ".join(normalized.split())


@lru_cache(maxsize=1)
def _food_terms() -> set[str]:
    terms = {normalize_food_text(term) for term in _fallback_food_terms}
    terms.update(normalize_food_text(alias) for alias in _french_aliases)
    terms.update(normalize_food_text(target) for target in _french_aliases.values())
    terms.update(_load_themealdb_ingredients())
    return {term for term in terms if term}


def _load_themealdb_ingredients() -> set[str]:
    try:
        request = Request(
            THE_MEAL_DB_INGREDIENTS_URL,
            headers={"User-Agent": "Komi/0.1"},
        )
        with urlopen(request, timeout=4) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except Exception:
        return set()

    meals = payload.get("meals")
    if not isinstance(meals, list):
        return set()

    ingredients = set()
    for meal in meals:
        if not isinstance(meal, dict):
            continue
        ingredient = str(meal.get("strIngredient") or "").strip()
        if ingredient:
            ingredients.add(normalize_food_text(ingredient))
    return ingredients


def _display_name(value: str) -> str:
    cleaned = " ".join(value.strip().split())
    if not cleaned:
        return ""
    return cleaned[0].upper() + cleaned[1:]


def _correct_food_name(value: str) -> str:
    normalized = normalize_food_text(value)
    return _food_corrections.get(normalized, value)


def _singularize(value: str) -> str:
    if value.endswith("es") and len(value) > 4:
        return value[:-1]
    if value.endswith("s") and len(value) > 3:
        return value[:-1]
    return value
