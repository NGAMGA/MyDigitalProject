import asyncio
import sys
import unittest
from io import BytesIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.database import Base
from app.routers.shopping_lists import (
    analyze_image,
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

    def test_analyzes_valid_image_and_filters_items(self) -> None:
        upload = UploadFile(
            file=BytesIO(b"\x89PNG\r\n\x1a\nvalid-image"),
            filename="liste.png",
            headers=Headers({"content-type": "image/png"}),
        )
        analysis = SimpleNamespace(
            raw_text="Tomates\nSavon",
            items=[
                SimpleNamespace(name="Tomates", confidence=0.98),
                SimpleNamespace(name="Savon", confidence=0.91),
            ],
        )
        with (
            patch(
                "app.routers.shopping_lists.analyze_shopping_list_image",
                return_value=analysis,
            ),
            patch(
                "app.routers.shopping_lists.classify_food_items",
                return_value=(["Tomates"], ["Savon"]),
            ),
        ):
            response = asyncio.run(
                analyze_image(
                    image=upload,
                    source="gallery",
                    current_user=self.user,
                )
            )

        self.assertEqual([item.name for item in response.items], ["Tomates"])
        self.assertEqual(
            [item.name for item in response.rejectedItems],
            ["Savon"],
        )

    def test_rejects_non_image_file(self) -> None:
        upload = UploadFile(
            file=BytesIO(b"not-an-image"),
            filename="liste.txt",
            headers=Headers({"content-type": "text/plain"}),
        )
        with self.assertRaises(HTTPException) as context:
            asyncio.run(
                analyze_image(
                    image=upload,
                    source="gallery",
                    current_user=self.user,
                )
            )
        self.assertEqual(context.exception.status_code, 400)

    def test_rejects_empty_image(self) -> None:
        upload = UploadFile(
            file=BytesIO(b""),
            filename="liste.png",
            headers=Headers({"content-type": "image/png"}),
        )
        with self.assertRaises(HTTPException) as context:
            asyncio.run(
                analyze_image(
                    image=upload,
                    source="gallery",
                    current_user=self.user,
                )
            )
        self.assertEqual(context.exception.status_code, 400)


if __name__ == "__main__":
    unittest.main()
