from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session
import stripe

from app import models, schemas
from app.config import settings
from app.database import get_db
from app.deps import get_current_user
from app.security import hash_password, validate_password_policy, verify_password
from app.serializers import join_full_name, serialize_user, split_full_name

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=schemas.UserPublic)
def get_me(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.UserPublic:
    invoices_count = db.execute(
        select(func.count(models.Invoice.id)).where(models.Invoice.user_id == current_user.id)
    ).scalar_one()
    return serialize_user(current_user, invoices_count=int(invoices_count))


@router.patch("/me", response_model=schemas.UserPublic)
def update_me(
    payload: schemas.UpdateProfileRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.UserPublic:
    provided_fields = payload.model_fields_set
    current_first_name, current_last_name = split_full_name(current_user.full_name)
    next_first_name = (current_user.first_name or current_first_name or "").strip()
    next_last_name = (current_user.last_name or current_last_name or "").strip()

    if "name" in provided_fields:
        next_first_name, next_last_name = split_full_name((payload.name or "").strip())

    if "firstName" in provided_fields:
        next_first_name = (payload.firstName or "").strip()

    if "lastName" in provided_fields:
        next_last_name = (payload.lastName or "").strip()

    current_user.first_name = next_first_name or None
    current_user.last_name = next_last_name or None
    current_user.full_name = join_full_name(next_first_name, next_last_name, payload.name or current_user.full_name)

    if "email" in provided_fields and payload.email is not None:
        next_email = payload.email.strip().lower()
        same_email = next_email == current_user.email
        if not same_email:
            existing = db.execute(select(models.User).where(models.User.email == next_email)).scalar_one_or_none()
            if existing:
                raise HTTPException(status_code=409, detail="Cet e-mail est deja utilise.")
            current_user.email = next_email

    if "phoneNumber" in provided_fields:
        current_user.phone_number = (payload.phoneNumber or "").strip() or None

    if "dateOfBirth" in provided_fields:
        current_user.date_of_birth = payload.dateOfBirth

    if "country" in provided_fields:
        current_user.country = (payload.country or "").strip() or None

    if "bio" in provided_fields:
        current_user.bio = (payload.bio or "").strip() or None

    if "avatarDataUrl" in provided_fields:
        current_user.avatar_data_url = (payload.avatarDataUrl or "").strip() or None

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    invoices_count = db.execute(
        select(func.count(models.Invoice.id)).where(models.Invoice.user_id == current_user.id)
    ).scalar_one()
    return serialize_user(current_user, invoices_count=int(invoices_count))


@router.post("/change-password")
def change_password(
    payload: schemas.ChangePasswordRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, bool]:
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Le mot de passe actuel est incorrect.")

    password_error = validate_password_policy(
        payload.next_password,
        email=current_user.email,
        name=current_user.full_name,
    )
    if password_error:
        raise HTTPException(status_code=400, detail=password_error)

    current_user.password_hash = hash_password(payload.next_password)
    db.add(current_user)
    db.commit()
    return {"ok": True}


@router.delete("/me", response_model=schemas.GenericMessageResponse)
def delete_me(
    payload: schemas.DeleteAccountRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.GenericMessageResponse:
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le mot de passe actuel est incorrect.",
        )

    subscription = current_user.subscription
    stripe_subscription_id = (
        subscription.stripe_subscription_id if subscription is not None else None
    )
    if stripe_subscription_id:
        if not settings.stripe_secret_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "Impossible de supprimer le compte tant que Stripe "
                    "n est pas configure."
                ),
            )
        stripe.api_key = settings.stripe_secret_key
        try:
            stripe.Subscription.cancel(stripe_subscription_id)
        except stripe.StripeError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=(
                    "Impossible d annuler l abonnement Stripe. "
                    "Le compte n a pas ete supprime."
                ),
            ) from exc

    db.delete(current_user)
    db.commit()
    return schemas.GenericMessageResponse(
        detail="Ton compte et tes donnees personnelles ont ete supprimes."
    )
