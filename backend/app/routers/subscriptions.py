import time
import uuid
from datetime import date, datetime, timedelta, timezone

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


def _date_from_timestamp(value) -> date | None:
    if value in {None, ""}:
        return None
    try:
        return datetime.fromtimestamp(int(value), tz=timezone.utc).date()
    except (TypeError, ValueError, OSError):
        return None


def _stripe_subscription_status(value: str | None) -> str:
    return {
        "trialing": "Essai gratuit",
        "active": "Actif",
        "past_due": "Paiement en retard",
        "unpaid": "Paiement echoue",
        "paused": "En pause",
        "canceled": "Annule",
        "incomplete": "Paiement incomplet",
        "incomplete_expired": "Expire",
    }.get(str(value or "").lower(), "Actif")


def _stripe_id(value) -> str | None:
    if isinstance(value, str):
        return value
    identifier = _stripe_value(value, "id")
    return str(identifier) if identifier else None


def _stripe_period_end(stripe_subscription) -> date | None:
    direct_period_end = _date_from_timestamp(
        _stripe_value(stripe_subscription, "current_period_end")
    )
    if direct_period_end is not None:
        return direct_period_end

    items = _stripe_value(stripe_subscription, "items")
    item_data = _stripe_value(items, "data") or []
    if item_data:
        return _date_from_timestamp(
            _stripe_value(item_data[0], "current_period_end")
        )
    return None


def _find_user_for_stripe_subscription(
    stripe_subscription,
    db: Session,
) -> models.User | None:
    subscription_id = _stripe_id(stripe_subscription)
    if subscription_id:
        local_subscription = (
            db.query(models.Subscription)
            .filter(models.Subscription.stripe_subscription_id == str(subscription_id))
            .first()
        )
        if local_subscription is not None:
            return local_subscription.user

    metadata = _stripe_value(stripe_subscription, "metadata") or {}
    user_id = _stripe_value(metadata, "user_id")
    if user_id:
        return db.get(models.User, str(user_id))

    customer_id = _stripe_id(_stripe_value(stripe_subscription, "customer"))
    if customer_id:
        local_subscription = (
            db.query(models.Subscription)
            .filter(models.Subscription.stripe_customer_id == str(customer_id))
            .first()
        )
        if local_subscription is not None:
            return local_subscription.user
    return None


def _sync_stripe_subscription(
    local_subscription: models.Subscription,
    stripe_subscription,
) -> None:
    stripe_status = str(_stripe_value(stripe_subscription, "status") or "")
    trial_end = _date_from_timestamp(
        _stripe_value(stripe_subscription, "trial_end")
    )
    period_end = _stripe_period_end(stripe_subscription)
    cancel_at_period_end = bool(
        _stripe_value(stripe_subscription, "cancel_at_period_end")
    )

    local_subscription.stripe_subscription_id = str(
        _stripe_id(stripe_subscription)
        or local_subscription.stripe_subscription_id
        or ""
    ) or None
    local_subscription.stripe_customer_id = str(
        _stripe_id(_stripe_value(stripe_subscription, "customer"))
        or local_subscription.stripe_customer_id
        or ""
    ) or None
    local_subscription.cancel_at_period_end = cancel_at_period_end
    local_subscription.trial_end_date = trial_end
    local_subscription.has_used_trial = bool(
        local_subscription.has_used_trial or trial_end or stripe_status == "trialing"
    )
    local_subscription.renewal_date = trial_end if stripe_status == "trialing" else period_end
    local_subscription.status = _stripe_subscription_status(stripe_status)

    if stripe_status in {"canceled", "incomplete_expired"}:
        local_subscription.plan = "Free"
        local_subscription.renewal_date = None
        local_subscription.trial_end_date = None
        local_subscription.cancel_at_period_end = False
    else:
        local_subscription.plan = "Premium"


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
    if not settings.stripe_secret_key or not settings.stripe_premium_price_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Paiement Stripe non configure. Ajoute STRIPE_SECRET_KEY et "
                "STRIPE_PREMIUM_PRICE_ID dans l'environnement backend."
            ),
        )

    stripe.api_key = settings.stripe_secret_key
    subscription = ensure_subscription(current_user, db)
    if subscription.plan == "Premium" and subscription.status not in {
        "Annule",
        "Expire",
    }:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un abonnement Premium est deja actif pour ce compte.",
        )

    try:
        checkout_options = {
            "mode": "subscription",
            "client_reference_id": current_user.id,
            "line_items": [
                {
                    "price": settings.stripe_premium_price_id,
                    "quantity": 1,
                }
            ],
            "success_url": settings.stripe_success_url,
            "cancel_url": settings.stripe_cancel_url,
            "metadata": {
                "user_id": current_user.id,
                "plan": "Premium",
            },
            "subscription_data": {
                "metadata": {"user_id": current_user.id, "plan": "Premium"},
            },
        }
        if subscription.stripe_customer_id:
            checkout_options["customer"] = subscription.stripe_customer_id
        else:
            checkout_options["customer_email"] = current_user.email
        if not subscription.has_used_trial:
            checkout_options["subscription_data"]["trial_period_days"] = (
                settings.stripe_trial_days
            )

        session = stripe.checkout.Session.create(**checkout_options)
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

    event_type = str(_stripe_value(event, "type") or "")
    event_object = _stripe_value(_stripe_value(event, "data"), "object")

    if event_type == "checkout.session.completed":
        user_id = _stripe_value(event_object, "client_reference_id")
        metadata = _stripe_value(event_object, "metadata") or {}
        user_id = user_id or _stripe_value(metadata, "user_id")
        user = db.get(models.User, str(user_id)) if user_id else None
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Utilisateur Komi introuvable.",
            )

        stripe_subscription_id = _stripe_id(
            _stripe_value(event_object, "subscription")
        )
        customer_id = _stripe_id(_stripe_value(event_object, "customer"))
        subscription = ensure_subscription(user, db)
        subscription.stripe_customer_id = (
            str(customer_id) if customer_id else subscription.stripe_customer_id
        )

        if stripe_subscription_id:
            stripe.api_key = settings.stripe_secret_key
            stripe_subscription = stripe.Subscription.retrieve(
                str(stripe_subscription_id)
            )
            _sync_stripe_subscription(subscription, stripe_subscription)
        else:
            subscription.plan = "Premium"
            subscription.status = "Essai gratuit"
            subscription.trial_end_date = date.today() + timedelta(
                days=settings.stripe_trial_days
            )
            subscription.renewal_date = subscription.trial_end_date
            subscription.has_used_trial = True

        db.add(subscription)
        db.commit()
        return schemas.GenericMessageResponse(detail="Essai Premium active.")

    if event_type in {
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
    }:
        user = _find_user_for_stripe_subscription(event_object, db)
        if user is None:
            return schemas.GenericMessageResponse(
                detail="Abonnement Stripe sans utilisateur Komi."
            )
        subscription = ensure_subscription(user, db)
        _sync_stripe_subscription(subscription, event_object)
        db.add(subscription)
        db.commit()
        return schemas.GenericMessageResponse(detail="Abonnement synchronise.")

    return schemas.GenericMessageResponse(detail="Evenement Stripe ignore.")


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
    if not subscription.stripe_subscription_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cet abonnement ne peut pas etre resilie automatiquement.",
        )
    if subscription.cancel_at_period_end:
        return serialize_subscription(subscription)

    stripe.api_key = settings.stripe_secret_key
    try:
        stripe_subscription = stripe.Subscription.modify(
            subscription.stripe_subscription_id,
            cancel_at_period_end=True,
        )
    except stripe.error.StripeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Stripe n a pas pu programmer la resiliation: {exc.user_message or str(exc)}",
        ) from exc

    _sync_stripe_subscription(subscription, stripe_subscription)
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return serialize_subscription(subscription)


@router.post("/me/resume", response_model=schemas.SubscriptionPublic)
def resume_subscription(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SubscriptionPublic:
    subscription = ensure_subscription(current_user, db)
    if not subscription.stripe_subscription_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cet abonnement n est pas gere par Stripe.",
        )
    if not subscription.cancel_at_period_end:
        return serialize_subscription(subscription)

    stripe.api_key = settings.stripe_secret_key
    try:
        stripe_subscription = stripe.Subscription.modify(
            subscription.stripe_subscription_id,
            cancel_at_period_end=False,
        )
    except stripe.error.StripeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Stripe n a pas pu reactiver l abonnement: {exc.user_message or str(exc)}",
        ) from exc

    _sync_stripe_subscription(subscription, stripe_subscription)
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return serialize_subscription(subscription)
