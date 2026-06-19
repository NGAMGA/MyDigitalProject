import asyncio
import sys
import unittest
from datetime import date, datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import models, schemas
from app.config import settings
from app.database import Base
from app.routers.subscriptions import (
    cancel_subscription,
    create_premium_checkout_session,
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
        self.assertEqual(plan_to_amount_cents("Premium"), 599)

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

    def test_checkout_starts_seven_day_trial_for_first_subscription(self) -> None:
        user = SimpleNamespace(
            id="trial-user",
            email="trial@example.com",
            subscription=models.Subscription(
                plan="Free",
                status="Actif",
                renewal_date=None,
                has_used_trial=False,
            ),
        )
        db = SimpleNamespace(add=lambda value: None, commit=lambda: None)

        with (
            patch.object(settings, "stripe_secret_key", "sk_test"),
            patch.object(settings, "stripe_premium_price_id", "price_test"),
            patch(
                "app.routers.subscriptions.stripe.checkout.Session.create",
                return_value=SimpleNamespace(url="https://checkout.stripe.test/session"),
            ) as create_session,
        ):
            response = create_premium_checkout_session(user, db)

        self.assertEqual(str(response.url), "https://checkout.stripe.test/session")
        options = create_session.call_args.kwargs
        self.assertEqual(options["subscription_data"]["trial_period_days"], 7)
        self.assertEqual(
            options["subscription_data"]["metadata"]["user_id"],
            user.id,
        )

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
        self.assertEqual(response.detail, "Essai Premium active.")
        self.assertEqual(user.subscription.plan, "Premium")
        self.assertEqual(user.subscription.status, "Essai gratuit")
        self.assertIsNotNone(user.subscription.renewal_date)
        self.assertTrue(user.subscription.has_used_trial)
        session.close()

    def test_cancel_schedules_stripe_subscription_end(self) -> None:
        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(engine)
        session = sessionmaker(bind=engine)()
        user = models.User(
            id="cancel-user",
            full_name="Cancel User",
            email="cancel-user@example.com",
            password_hash="unused",
        )
        user.subscription = models.Subscription(
            plan="Premium",
            status="Essai gratuit",
            renewal_date=date(2026, 6, 26),
            trial_end_date=date(2026, 6, 26),
            stripe_customer_id="cus_test",
            stripe_subscription_id="sub_test",
            has_used_trial=True,
        )
        session.add(user)
        session.commit()
        trial_end = int(
            datetime(2026, 6, 26, tzinfo=timezone.utc).timestamp()
        )

        with (
            patch.object(settings, "stripe_secret_key", "sk_test"),
            patch(
                "app.routers.subscriptions.stripe.Subscription.modify",
                return_value={
                    "id": "sub_test",
                    "customer": "cus_test",
                    "status": "trialing",
                    "trial_end": trial_end,
                    "items": {
                        "data": [{"current_period_end": trial_end}],
                    },
                    "cancel_at_period_end": True,
                },
            ) as modify_subscription,
        ):
            response = cancel_subscription(user, session)

        self.assertTrue(response.cancelAtPeriodEnd)
        self.assertEqual(response.plan, "Premium")
        self.assertEqual(response.status, "Essai gratuit")
        self.assertEqual(response.renewal, "2026-06-26")
        modify_subscription.assert_called_once_with(
            "sub_test",
            cancel_at_period_end=True,
        )
        session.close()


if __name__ == "__main__":
    unittest.main()
