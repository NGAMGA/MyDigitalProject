import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

from fastapi import HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.routers.menus import check_subscription


class MenusSubscriptionTest(unittest.TestCase):
    def test_accepts_free_as_standard_access(self) -> None:
        user = SimpleNamespace(subscription=SimpleNamespace(plan="Free"))

        check_subscription(user, "Standard")

    def test_rejects_free_for_premium_access(self) -> None:
        user = SimpleNamespace(subscription=SimpleNamespace(plan="Free"))

        with self.assertRaises(HTTPException) as context:
            check_subscription(user, "Premium")

        self.assertEqual(context.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
