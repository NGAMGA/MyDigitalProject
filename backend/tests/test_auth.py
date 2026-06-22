import sys
import unittest
from pathlib import Path
from urllib.parse import parse_qs, urlparse
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.config import settings
from app.database import Base
from app.routers.auth import forgot_password, reset_password
from app.security import hash_password, verify_password


class AuthPasswordResetTest(unittest.TestCase):
    def setUp(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()
        self.user = models.User(
            id="reset-user",
            full_name="Reset User",
            email="reset@example.com",
            password_hash=hash_password("OldPassword1!"),
        )
        self.user.subscription = models.Subscription(plan="Free", status="Actif")
        self.db.add(self.user)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_forgot_then_reset_password(self) -> None:
        with (
            patch.object(settings, "frontend_base_url", "http://localhost:5454"),
            patch.object(settings, "expose_password_reset_link_in_response", True),
            patch("app.routers.auth.send_password_reset_email", return_value=True),
        ):
            forgot = forgot_password(
                schemas.ForgotPasswordRequest(email=self.user.email),
                db=self.db,
            )

        self.assertIsNotNone(forgot.debugResetLink)
        token = parse_qs(urlparse(forgot.debugResetLink).query)["resetToken"][0]
        response = reset_password(
            schemas.ResetPasswordRequest(
                token=token,
                password="NewPassword2!",
            ),
            db=self.db,
        )

        self.db.refresh(self.user)
        self.assertIn("mis a jour", response.detail)
        self.assertTrue(verify_password("NewPassword2!", self.user.password_hash))

        with self.assertRaises(HTTPException):
            reset_password(
                schemas.ResetPasswordRequest(
                    token=token,
                    password="AnotherPassword3!",
                ),
                db=self.db,
            )

    def test_forgot_password_does_not_reveal_unknown_email(self) -> None:
        response = forgot_password(
            schemas.ForgotPasswordRequest(email="unknown@example.com"),
            db=self.db,
        )
        self.assertIn("Si un compte existe", response.detail)
        self.assertIsNone(response.debugResetLink)


if __name__ == "__main__":
    unittest.main()
