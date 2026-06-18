import asyncio
import sys
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.config import settings
from app.database import Base
from app.routers.subscriptions import (
    handle_stripe_webhook,
    list_subscription_plans,
    normalize_renewal_date,
    plan_to_amount_cents,
    update_subscription,
)


class FakeRequest:
    async def body(self) -> bytes:
        return b'{"type":"checkout.session.completed"}'


class SubscriptionsTest(unittest.TestCase):
    def test_lists_available_plans(self) -> None:
        plans = list_subscription_plans()

        self.assertEqual([plan.name for plan in plans], ["Free", "Premium", "Pro"])
        self.assertEqual(plan_to_amount_cents("Premium"), 600)

    def test_renewal_date_rules(self) -> None:
        custom_date = date(2026, 7, 1)

        self.assertIsNone(normalize_renewal_date("Free", "Actif", custom_date))
        self.assertIsNone(normalize_renewal_date("Premium", "Annule", custom_date))
        self.assertEqual(normalize_renewal_date("Premium", "Actif", custom_date), custom_date)
        self.assertIsNotNone(normalize_renewal_date("Premium", "Actif", None))

    def test_rejects_direct_premium_upgrade(self) -> None:
        payload = schemas.SubscriptionUpdateRequest(plan="Premium")

        with self.assertRaises(HTTPException) as context:
            update_subscription(payload, current_user=None, db=None)

        self.assertEqual(context.exception.status_code, 403)

    def test_stripe_webhook_activates_premium(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        session = sessionmaker(bind=engine)()
        user = models.User(
            id="stripe-user",
            full_name="Stripe User",
            email="stripe-user@example.com",
            password_hash="unused",
        )
        user.subscription = models.Subscription(
            plan="Free",
            status="Actif",
            renewal_date=None,
        )
        session.add(user)
        session.commit()

        event = {
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "client_reference_id": user.id,
                    "metadata": {"user_id": user.id},
                }
            },
        }

        with (
            patch.object(settings, "stripe_webhook_secret", "whsec_test"),
            patch(
                "app.routers.subscriptions.stripe.Webhook.construct_event",
                return_value=event,
            ),
        ):
            response = asyncio.run(
                handle_stripe_webhook(
                    FakeRequest(),
                    stripe_signature="test-signature",
                    db=session,
                )
            )

        session.refresh(user.subscription)
        self.assertEqual(response.detail, "Abonnement Premium active.")
        self.assertEqual(user.subscription.plan, "Premium")
        self.assertEqual(user.subscription.status, "Actif")
        self.assertIsNotNone(user.subscription.renewal_date)
        session.close()


if __name__ == "__main__":
    unittest.main()
