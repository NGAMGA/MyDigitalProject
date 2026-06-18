import time
import uuid
from datetime import date, timedelta

import stripe
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import models, schemas
from app.config import settings
from app.database import get_db
from app.deps import get_current_user
from app.serializers import serialize_subscription

router = APIRouter(prefix="/subscription", tags=["subscription"])

SUBSCRIPTION_PLANS: dict[str, schemas.SubscriptionPlanPublic] = {
    "Free": schemas.SubscriptionPlanPublic(
        name="Free",
        label="Gratuit",
        amountCents=0,
        billingPeriod="none",
        features=["Compte Komi", "Recettes de base", "Favoris"],
    ),
    "Premium": schemas.SubscriptionPlanPublic(
        name="Premium",
        label="Premium",
        amountCents=600,
        billingPeriod="monthly",
        features=["Recettes avancees", "Listes de courses", "Filtrage alimentaire"],
    ),
    "Pro": schemas.SubscriptionPlanPublic(
        name="Pro",
        label="Pro",
        amountCents=1999,
        billingPeriod="monthly",
        features=["Toutes les fonctions Premium", "Suivi prioritaire", "Exports avances"],
    ),
}


def plan_to_amount_cents(plan: str) -> int:
    return SUBSCRIPTION_PLANS[plan].amountCents


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


def normalize_renewal_date(plan: str, status: str, renewal: date | None) -> date | None:
    if plan == "Free" or status != "Actif":
        return None
    return renewal or date.today() + timedelta(days=30)


@router.get("/plans", response_model=list[schemas.SubscriptionPlanPublic])
def list_subscription_plans() -> list[schemas.SubscriptionPlanPublic]:
    return list(SUBSCRIPTION_PLANS.values())


@router.get("/me", response_model=schemas.SubscriptionPublic)
def get_subscription(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    subscription = ensure_subscription(current_user, db)
    return serialize_subscription(subscription)


@router.post("/checkout/premium", response_model=schemas.CheckoutSessionPublic)
def create_premium_checkout_session(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.CheckoutSessionPublic:
    _ = db

    if not settings.stripe_secret_key or not settings.stripe_premium_price_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Paiement Stripe non configure. Ajoute STRIPE_SECRET_KEY et "
                "STRIPE_PREMIUM_PRICE_ID dans l'environnement backend."
            ),
        )

    stripe.api_key = settings.stripe_secret_key

    try:
        session = stripe.checkout.Session.create(
            mode="subscription",
            customer_email=current_user.email,
            client_reference_id=current_user.id,
            line_items=[
                {
                    "price": settings.stripe_premium_price_id,
                    "quantity": 1,
                }
            ],
            success_url=settings.stripe_success_url,
            cancel_url=settings.stripe_cancel_url,
            metadata={
                "user_id": current_user.id,
                "plan": "Premium",
            },
        )
    except stripe.error.StripeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Stripe a refuse la creation du paiement: {exc.user_message or str(exc)}",
        ) from exc

    if not session.url:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Stripe n'a pas renvoye d'URL de paiement.",
        )

    return schemas.CheckoutSessionPublic(url=session.url)


@router.put("/me", response_model=schemas.SubscriptionPublic)
def update_subscription(
    payload: schemas.SubscriptionUpdateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    if payload.plan not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="Plan d'abonnement invalide.")

    subscription = ensure_subscription(current_user, db)
    previous_plan = subscription.plan

    subscription.plan = payload.plan
    subscription.status = payload.status
    subscription.renewal_date = normalize_renewal_date(payload.plan, payload.status, payload.renewal)

    if previous_plan != subscription.plan and plan_to_amount_cents(subscription.plan) > 0:
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


@router.post("/me/cancel", response_model=schemas.SubscriptionPublic)
def cancel_subscription(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    subscription = ensure_subscription(current_user, db)
    subscription.status = "Annule"
    subscription.renewal_date = None

    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return serialize_subscription(subscription)
