import sys
import unittest
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.database import Base
from app.routers.shopping_lists import (
    create_new_list,
    get_current_list,
    get_list_history,
    replace_current_items,
)


class ShoppingListsTest(unittest.TestCase):
    def setUp(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()
        self.user = models.User(
            id="shopping-user",
            full_name="Shopping User",
            email="shopping@example.com",
            password_hash="unused",
        )
        self.user.subscription = models.Subscription(
            plan="Free",
            status="Actif",
        )
        self.db.add(self.user)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_persists_current_list_items(self) -> None:
        current = get_current_list(current_user=self.user, db=self.db)
        self.assertEqual(current.items, [])

        payload = schemas.ShoppingListReplaceItemsRequest(
            items=[
                schemas.ShoppingProductPayload(
                    name="Riz",
                    brand="Komi",
                    quantity=2,
                    nutriScore="B",
                )
            ]
        )
        updated = replace_current_items(
            payload,
            current_user=self.user,
            db=self.db,
        )

        self.assertEqual(updated.items[0].name, "Riz")
        self.assertEqual(updated.items[0].quantity, 2)

    def test_premium_keeps_previous_list_in_history(self) -> None:
        self.user.subscription.plan = "Premium"
        self.db.commit()
        get_current_list(current_user=self.user, db=self.db)

        create_new_list(
            schemas.ShoppingListCreateRequest(name="Nouvelle liste"),
            current_user=self.user,
            db=self.db,
        )
        history = get_list_history(current_user=self.user, db=self.db)

        self.assertEqual(len(history), 2)
        self.assertTrue(history[0].isActive)
        self.assertFalse(history[1].isActive)


if __name__ == "__main__":
    unittest.main()
