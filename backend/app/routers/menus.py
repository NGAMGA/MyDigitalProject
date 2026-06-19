import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.deps import get_current_user
from app import models
from app.database import get_db

router = APIRouter(prefix="/menus", tags=["menus"])

THEMEALDB_URL = "https://www.themealdb.com/api/json/v1/1"


def check_subscription(current_user: models.User, required: str = "Standard"):
    if current_user.subscription is None:
        raise HTTPException(status_code=403, detail="Abonnement requis")

    plan_ranks = {
        "Free": 0,
        "Standard": 0,
        "Premium": 1,
        "Pro": 2,
    }
    current_rank = plan_ranks.get(current_user.subscription.plan, -1)
    required_rank = plan_ranks.get(required)
    if required_rank is None:
        raise HTTPException(status_code=500, detail="Niveau d'abonnement invalide")
    if required_rank > 0 and getattr(
        current_user.subscription, "status", "Actif"
    ) not in {
        "Actif",
        "Essai gratuit",
    }:
        raise HTTPException(status_code=403, detail="Abonnement Premium inactif")
    if current_rank < required_rank:
        raise HTTPException(status_code=403, detail=f"Abonnement {required} requis")


@router.post("/suggestions")
async def suggest_menus(
    ingredients: list[str],
    current_user: models.User = Depends(get_current_user)
):
    check_subscription(current_user, "Standard")

    suggestions = []
    for ingredient in ingredients[:5]:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{THEMEALDB_URL}/filter.php",
                params={"i": ingredient}
            )
            data = response.json()
            if data.get("meals"):
                suggestions.extend(data["meals"][:3])

    seen = set()
    unique = []
    for meal in suggestions:
        if meal["idMeal"] not in seen:
            seen.add(meal["idMeal"])
            unique.append(meal)

    return {"suggestions": unique[:10]}


@router.get("/search")
async def search_menus(
    name: str = None,
    ingredient: str = None,
    region: str = None,
    current_user: models.User = Depends(get_current_user)
):
    check_subscription(current_user, "Premium")

    async with httpx.AsyncClient() as client:
        if name:
            response = await client.get(f"{THEMEALDB_URL}/search.php", params={"s": name})
        elif ingredient:
            response = await client.get(f"{THEMEALDB_URL}/filter.php", params={"i": ingredient})
        elif region:
            response = await client.get(f"{THEMEALDB_URL}/filter.php", params={"a": region})
        else:
            raise HTTPException(status_code=400, detail="Précisez un nom, ingrédient ou région")

    data = response.json()
    meals = data.get("meals") or []
    return {"results": meals}


@router.get("/regions")
async def get_regions(
    current_user: models.User = Depends(get_current_user)
):
    check_subscription(current_user, "Premium")

    async with httpx.AsyncClient() as client:
        response = await client.get(f"{THEMEALDB_URL}/list.php", params={"a": "list"})

    data = response.json()
    return {"regions": data.get("meals") or []}


@router.get("/detail/{meal_id}")
async def get_meal_detail(
    meal_id: str,
    current_user: models.User = Depends(get_current_user)
):
    check_subscription(current_user, "Premium")

    async with httpx.AsyncClient() as client:
        response = await client.get(f"{THEMEALDB_URL}/lookup.php", params={"i": meal_id})

    data = response.json()
    meals = data.get("meals")
    if not meals:
        raise HTTPException(status_code=404, detail="Menu non trouvé")
    return {"meal": meals[0]}



@router.get("/cart")
async def get_cart(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    check_subscription(current_user, "Premium")

    items = db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id
    ).all()

    return {"items": items}


@router.post("/cart/add")
async def add_to_cart(
    meal_id: str,
    meal_name: str = None,
    meal_thumb: str = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    check_subscription(current_user, "Premium")

    existing = db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id,
        models.CartItem.meal_id == meal_id
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Ce menu est déjà dans le panier")

    new_item = models.CartItem(
        user_id=current_user.id,
        meal_id=meal_id,
        meal_name=meal_name,
        meal_thumb=meal_thumb
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)

    return {"message": "Menu ajouté au panier", "item": new_item}


@router.delete("/cart/{meal_id}")
async def remove_from_cart(
    meal_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    check_subscription(current_user, "Premium")

    item = db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id,
        models.CartItem.meal_id == meal_id
    ).first()

    if not item:
        raise HTTPException(status_code=404, detail="Menu non trouvé dans le panier")

    db.delete(item)
    db.commit()

    return {"message": "Menu retiré du panier"}


@router.post("/cart/generate-list")
async def generate_shopping_list(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    check_subscription(current_user, "Premium")

    cart_items = db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id
    ).all()

    if not cart_items:
        raise HTTPException(status_code=400, detail="Le panier est vide")

    shopping_list = []
    recipes = []

    async with httpx.AsyncClient() as client:
        for item in cart_items:
            response = await client.get(f"{THEMEALDB_URL}/lookup.php", params={"i": item.meal_id})
            data = response.json()
            meals = data.get("meals")

            if not meals:
                continue

            meal = meals[0]

            ingredients = []
            for i in range(1, 21):
                ingredient = meal.get(f"strIngredient{i}")
                measure = meal.get(f"strMeasure{i}")
                if ingredient and ingredient.strip():
                    ingredients.append({
                        "ingredient": ingredient.strip(),
                        "measure": measure.strip() if measure else ""
                    })

            shopping_list.extend(ingredients)

            recipes.append({
                "meal_id": meal.get("idMeal"),
                "name": meal.get("strMeal"),
                "instructions": meal.get("strInstructions"),
                "thumbnail": meal.get("strMealThumb"),
                "ingredients": ingredients
            })

    return {
        "shopping_list": shopping_list,
        "recipes": recipes
    }


@router.get("/nutrition-tips")
async def nutrition_tips(
    ingredients: list[str],
    current_user: models.User = Depends(get_current_user)
):
    check_subscription(current_user, "Standard")

    tips = []

    keywords = {
        "poulet": "Le poulet est une excellente source de protéines maigres.",
        "poisson": "Le poisson est riche en oméga-3, bénéfiques pour le cœur.",
        "légumes": "Les légumes apportent fibres et vitamines essentielles.",
        "huile": "Réduisez l'excès d'huile, préférez l'huile d'olive en petite quantité.",
        "sucre": "Limitez le sucre raffiné pour éviter les pics de glycémie.",
        "riz": "Le riz complet est préférable au riz blanc pour ses fibres.",
        "pâtes": "Privilégiez les pâtes complètes pour un apport en fibres.",
        "lait": "Le lait apporte du calcium essentiel pour les os.",
        "œuf": "Les œufs sont riches en protéines et en vitamines.",
        "viande": "Consommez la viande rouge avec modération.",
    }

    for ingredient in ingredients:
        for keyword, tip in keywords.items():
            if keyword.lower() in ingredient.lower():
                if tip not in tips:
                    tips.append(tip)

    if not tips:
        tips = [
            "Variez votre alimentation pour couvrir tous vos besoins nutritionnels.",
            "Buvez suffisamment d'eau chaque jour (1,5 à 2 litres).",
            "Privilégiez les aliments frais aux produits transformés.",
        ]

    return {"tips": tips}
