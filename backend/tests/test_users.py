import sys
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.config import settings
from app.database import Base
from app.routers.users import change_password, delete_me, update_me
from app.security import hash_password, verify_password


class UsersTest(unittest.TestCase):
    def setUp(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()
        self.user = models.User(
            id="delete-user",
            full_name="Delete User",
            email="delete@example.com",
            password_hash=hash_password("StrongPassword1!"),
        )
        self.user.subscription = models.Subscription(
            plan="Free",
            status="Actif",
        )
        self.user.shopping_lists.append(models.ShoppingList(name="Ma liste"))
        self.user.cart_items.append(
            models.CartItem(meal_id="42", meal_name="Test meal")
        )
        self.db.add(self.user)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_deletes_user_and_related_data(self) -> None:
        response = delete_me(
            schemas.DeleteAccountRequest(
                currentPassword="StrongPassword1!",
                confirmation="SUPPRIMER",
            ),
            current_user=self.user,
            db=self.db,
        )

        self.assertIn("supprimes", response.detail)
        self.assertIsNone(self.db.get(models.User, "delete-user"))
        self.assertEqual(
            self.db.execute(select(models.ShoppingList)).scalars().all(),
            [],
        )
        self.assertEqual(
            self.db.execute(select(models.CartItem)).scalars().all(),
            [],
        )

    def test_rejects_wrong_password_without_deleting_user(self) -> None:
        with self.assertRaises(HTTPException) as context:
            delete_me(
                schemas.DeleteAccountRequest(
                    currentPassword="WrongPassword1!",
                    confirmation="SUPPRIMER",
                ),
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(context.exception.status_code, 400)
        self.assertIsNotNone(self.db.get(models.User, "delete-user"))

    def test_cancels_stripe_subscription_before_deletion(self) -> None:
        self.user.subscription.plan = "Premium"
        self.user.subscription.stripe_subscription_id = "sub_test"
        self.db.commit()

        with (
            patch.object(settings, "stripe_secret_key", "sk_test"),
            patch("app.routers.users.stripe.Subscription.cancel") as cancel,
        ):
            delete_me(
                schemas.DeleteAccountRequest(
                    currentPassword="StrongPassword1!",
                    confirmation="SUPPRIMER",
                ),
                current_user=self.user,
                db=self.db,
            )

        cancel.assert_called_once_with("sub_test")
        self.assertIsNone(self.db.get(models.User, "delete-user"))

    def test_updates_profile_persistently(self) -> None:
        response = update_me(
            schemas.UpdateProfileRequest(
                firstName="Nouveau",
                lastName="Nom",
                country="France",
            ),
            current_user=self.user,
            db=self.db,
        )
        self.db.expire_all()
        persisted = self.db.get(models.User, "delete-user")
        self.assertEqual(response.profile.firstName, "Nouveau")
        self.assertEqual(persisted.first_name, "Nouveau")
        self.assertEqual(persisted.country, "France")

    def test_changes_password(self) -> None:
        response = change_password(
            schemas.ChangePasswordRequest(
                currentPassword="StrongPassword1!",
                nextPassword="NewPassword2!",
            ),
            current_user=self.user,
            db=self.db,
        )
        self.db.refresh(self.user)
        self.assertTrue(response["ok"])
        self.assertTrue(verify_password("NewPassword2!", self.user.password_hash))


if __name__ == "__main__":
    unittest.main()
