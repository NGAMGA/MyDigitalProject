import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import schemas
from app.routers.food_filter import filter_food_items


class FoodFilterTest(unittest.TestCase):
    def test_keeps_food_and_rejects_non_food_items(self) -> None:
        payload = schemas.FoodFilterRequest.model_validate(
            {
                "items": [
                    "pommes",
                    "lessive",
                    {"name": "riz basmati", "quantity": "1 kg"},
                    "papier toilette",
                    "tomates",
                ]
            }
        )

        result = filter_food_items(payload)

        self.assertEqual(result.totalItems, 5)
        self.assertEqual({item.name for item in result.foodItems}, {"pommes", "riz basmati", "tomates"})
        self.assertEqual({item.name for item in result.rejectedItems}, {"lessive", "papier toilette"})

    def test_uses_category_when_item_name_is_ambiguous(self) -> None:
        payload = schemas.FoodFilterRequest.model_validate(
            {"items": [{"name": "selection du marche", "category": "Fruits"}]}
        )

        result = filter_food_items(payload)

        self.assertEqual(result.foodCount, 1)
        self.assertEqual(result.foodItems[0].category, "Fruits")


if __name__ == "__main__":
    unittest.main()
