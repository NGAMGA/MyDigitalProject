import time
import uuid
from datetime import date, timedelta

import stripe
from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
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
        label="Standard",
        amountCents=0,
        billingPeriod="none",
        features=[
            "Une liste de courses persistante",
            "Ajout manuel et import photo",
            "Bilan nutritionnel de base",
            "Suggestions sur 2 ingredients",
        ],
    ),
    "Premium": schemas.SubscriptionPlanPublic(
        name="Premium",
        label="Premium",
        amountCents=600,
        billingPeriod="monthly",
        features=[
            "Plusieurs listes de courses",
            "Historique complet",
            "Suggestions sur 5 ingredients",
            "Jusqu a 6 recettes personnalisees",
        ],
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


@router.post("/webhook", response_model=schemas.GenericMessageResponse)
async def handle_stripe_webhook(
    request: Request,
    stripe_signature: str | None = Header(default=None, alias="Stripe-Signature"),
    db: Session = Depends(get_db),
) -> schemas.GenericMessageResponse:
    if not settings.stripe_webhook_secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Webhook Stripe non configure.",
        )
    if not stripe_signature:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signature Stripe manquante.",
        )

    payload = await request.body()
    try:
        event = stripe.Webhook.construct_event(
            payload,
            stripe_signature,
            settings.stripe_webhook_secret,
        )
    except (ValueError, stripe.error.SignatureVerificationError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Webhook Stripe invalide.",
        ) from exc

    event_type = _stripe_value(event, "type")
    if event_type != "checkout.session.completed":
        return schemas.GenericMessageResponse(detail="Evenement Stripe ignore.")

    session = _stripe_value(_stripe_value(event, "data"), "object")
    user_id = _stripe_value(session, "client_reference_id")
    metadata = _stripe_value(session, "metadata") or {}
    user_id = user_id or _stripe_value(metadata, "user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Utilisateur Stripe introuvable dans la session.",
        )

    user = db.get(models.User, str(user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur Komi introuvable.",
        )

    subscription = ensure_subscription(user, db)
    subscription.plan = "Premium"
    subscription.status = "Actif"
    subscription.renewal_date = date.today() + timedelta(days=30)
    db.add(subscription)
    db.commit()

    return schemas.GenericMessageResponse(detail="Abonnement Premium active.")


@router.put("/me", response_model=schemas.SubscriptionPublic)
def update_subscription(
    payload: schemas.SubscriptionUpdateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    if payload.plan not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="Plan d'abonnement invalide.")
    if payload.plan != "Free":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Le passage Premium doit etre valide par Stripe Checkout.",
        )

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


def _stripe_value(value, key: str):
    if value is None:
        return None
    if isinstance(value, dict):
        return value.get(key)
    return getattr(value, key, None)


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
