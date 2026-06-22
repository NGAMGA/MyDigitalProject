import asyncio
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models
from app.database import Base
from app.routers.menus import (
    add_to_cart,
    check_subscription,
    generate_shopping_list,
    get_cart,
    nutrition_tips,
    remove_from_cart,
)


class FakeMealResponse:
    def json(self):
        return {
            "meals": [
                {
                    "idMeal": "meal-1",
                    "strMeal": "Poulet riz",
                    "strInstructions": "Cuire puis servir.",
                    "strMealThumb": "https://example.com/meal.jpg",
                    "strIngredient1": "Rice",
                    "strMeasure1": "200 g",
                    "strIngredient2": "Chicken",
                    "strMeasure2": "2 pieces",
                    "strIngredient3": "Rice",
                    "strMeasure3": "100 g",
                }
            ]
        }


class FakeAsyncClient:
    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False

    async def get(self, url, params=None):
        _ = url, params
        return FakeMealResponse()


class MenusSubscriptionTest(unittest.TestCase):
    def setUp(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()
        self.user = models.User(
            id="menu-user",
            full_name="Menu User",
            email="menu@example.com",
            password_hash="unused",
        )
        self.user.subscription = models.Subscription(
            plan="Premium",
            status="Actif",
        )
        self.db.add(self.user)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_accepts_free_as_standard_access(self) -> None:
        user = SimpleNamespace(subscription=SimpleNamespace(plan="Free"))

        check_subscription(user, "Standard")

    def test_rejects_free_for_premium_access(self) -> None:
        user = SimpleNamespace(subscription=SimpleNamespace(plan="Free"))

        with self.assertRaises(HTTPException) as context:
            check_subscription(user, "Premium")

        self.assertEqual(context.exception.status_code, 403)

    def test_add_list_and_remove_cart_item(self) -> None:
        response = asyncio.run(
            add_to_cart(
                meal_id="meal-1",
                meal_name="Poulet riz",
                meal_thumb="https://example.com/meal.jpg",
                current_user=self.user,
                db=self.db,
            )
        )
        self.assertEqual(response["item"].meal_id, "meal-1")

        cart = asyncio.run(get_cart(current_user=self.user, db=self.db))
        self.assertEqual(len(cart["items"]), 1)

        asyncio.run(
            remove_from_cart(
                meal_id="meal-1",
                current_user=self.user,
                db=self.db,
            )
        )
        cart = asyncio.run(get_cart(current_user=self.user, db=self.db))
        self.assertEqual(cart["items"], [])

    def test_rejects_duplicate_cart_item(self) -> None:
        asyncio.run(
            add_to_cart(
                meal_id="meal-1",
                current_user=self.user,
                db=self.db,
            )
        )
        with self.assertRaises(HTTPException) as context:
            asyncio.run(
                add_to_cart(
                    meal_id="meal-1",
                    current_user=self.user,
                    db=self.db,
                )
            )
        self.assertEqual(context.exception.status_code, 400)

    def test_generates_consolidated_shopping_list(self) -> None:
        asyncio.run(
            add_to_cart(
                meal_id="meal-1",
                meal_name="Poulet riz",
                current_user=self.user,
                db=self.db,
            )
        )
        with patch(
            "app.routers.menus.httpx.AsyncClient",
            return_value=FakeAsyncClient(),
        ):
            response = asyncio.run(
                generate_shopping_list(
                    current_user=self.user,
                    db=self.db,
                )
            )

        self.assertEqual(len(response["recipes"]), 1)
        self.assertEqual(
            response["shopping_list"],
            [
                {"ingredient": "Rice", "measure": "200 g + 100 g"},
                {"ingredient": "Chicken", "measure": "2 pieces"},
            ],
        )

    def test_rejects_generation_with_empty_cart(self) -> None:
        with self.assertRaises(HTTPException) as context:
            asyncio.run(
                generate_shopping_list(
                    current_user=self.user,
                    db=self.db,
                )
            )
        self.assertEqual(context.exception.status_code, 400)

    def test_premium_receives_nutrition_tips(self) -> None:
        response = asyncio.run(
            nutrition_tips(
                ingredients=["poulet", "riz"],
                current_user=self.user,
            )
        )
        self.assertGreaterEqual(len(response["tips"]), 2)

    def test_standard_cannot_access_nutrition_tips(self) -> None:
        self.user.subscription.plan = "Free"
        self.db.commit()
        with self.assertRaises(HTTPException) as context:
            asyncio.run(
                nutrition_tips(
                    ingredients=["poulet"],
                    current_user=self.user,
                )
            )
        self.assertEqual(context.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
