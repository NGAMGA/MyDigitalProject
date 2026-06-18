import sys
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.routers.subscriptions import list_subscription_plans, normalize_renewal_date, plan_to_amount_cents


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


if __name__ == "__main__":
    unittest.main()
