import time
import uuid
from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user
from app.serializers import serialize_subscription

router = APIRouter(prefix="/subscription", tags=["subscription"])


def plan_to_amount_cents(plan: str) -> int:
    mapping = {
        "Free": 0,
        "Premium": 999,
        "Pro": 1999,
    }
    return mapping.get(plan, 0)


def ensure_subscription(user: models.User, db: Session) -> models.Subscription:
    if user.subscription is None:
        user.subscription = models.Subscription(plan="Free", status="Actif", renewal_date=None)
        db.add(user)
        db.commit()
        db.refresh(user)
    return user.subscription


def create_invoice(db: Session, user_id: str, label: str, amount_cents: int, status: str = "Payee") -> models.Invoice:
    invoice = models.Invoice(
        id=str(uuid.uuid4()),
        reference=f"FAC-{str(int(time.time() * 1000))[-8:]}",
        user_id=user_id,
        issue_date=date.today(),
        label=label,
        amount_cents=amount_cents,
        status=status,
    )
    db.add(invoice)
    return invoice


@router.get("/me", response_model=schemas.SubscriptionPublic)
def get_subscription(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    subscription = ensure_subscription(current_user, db)
    return serialize_subscription(subscription)


@router.put("/me", response_model=schemas.SubscriptionPublic)
def update_subscription(
    payload: schemas.SubscriptionUpdateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    subscription = ensure_subscription(current_user, db)
    previous_plan = subscription.plan

    subscription.plan = payload.plan.strip()
    subscription.status = payload.status.strip()
    subscription.renewal_date = payload.renewal

    if previous_plan != subscription.plan:
        create_invoice(
            db=db,
            user_id=current_user.id,
            label=f"Abonnement {subscription.plan}",
            amount_cents=plan_to_amount_cents(subscription.plan),
            status="Payee",
        )

    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return serialize_subscription(subscription)
