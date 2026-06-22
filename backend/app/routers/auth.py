import uuid
from datetime import datetime, timedelta, timezone
import logging
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app import models, schemas
from app.config import settings
from app.database import get_db
from app.mailer import send_password_reset_email
from app.security import (
    create_access_token,
    create_password_reset_token,
    hash_password,
    hash_reset_token,
    validate_password_policy,
    verify_password,
)
from app.serializers import serialize_user, split_full_name

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)


def _build_reset_url(token: str) -> str:
    base_url = settings.frontend_base_url.rstrip("/")
    return f"{base_url}/?resetToken={quote(token, safe='')}"


@router.post("/register", response_model=schemas.TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: schemas.AuthRegisterRequest, db: Session = Depends(get_db)) -> schemas.TokenResponse:
    email = payload.email.strip().lower()
    name = payload.name.strip()

    existing_user = db.execute(select(models.User).where(models.User.email == email)).scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=409, detail="Un compte existe deja avec cet e-mail.")

    password_error = validate_password_policy(payload.password, email=email, name=name)
    if password_error:
        raise HTTPException(status_code=400, detail=password_error)

    first_name, last_name = split_full_name(name)
    user = models.User(
        id=str(uuid.uuid4()),
        full_name=name,
        first_name=first_name or None,
        last_name=last_name or None,
        email=email,
        password_hash=hash_password(payload.password),
    )
    user.subscription = models.Subscription(plan="Free", status="Actif", renewal_date=None)

    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return schemas.TokenResponse(access_token=token, user=serialize_user(user, invoices_count=0))


@router.post("/login", response_model=schemas.TokenResponse)
def login(payload: schemas.AuthLoginRequest, db: Session = Depends(get_db)) -> schemas.TokenResponse:
    email = payload.email.strip().lower()
    user = db.execute(select(models.User).where(models.User.email == email)).scalar_one_or_none()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Identifiants incorrects.")

    invoices_count = db.execute(
        select(func.count(models.Invoice.id)).where(models.Invoice.user_id == user.id)
    ).scalar_one()
    token = create_access_token(user.id)
    return schemas.TokenResponse(access_token=token, user=serialize_user(user, invoices_count=int(invoices_count)))


@router.post("/forgot-password", response_model=schemas.ForgotPasswordResponse)
def forgot_password(
    payload: schemas.ForgotPasswordRequest,
    db: Session = Depends(get_db),
) -> schemas.ForgotPasswordResponse:
    email = payload.email.strip().lower()
    generic_message = "Si un compte existe avec cet e-mail, un lien de reinitialisation a ete envoye."
    response = schemas.ForgotPasswordResponse(detail=generic_message)

    user = db.execute(select(models.User).where(models.User.email == email)).scalar_one_or_none()
    if not user:
        return response

    now = datetime.now(timezone.utc)
    raw_token, token_hash = create_password_reset_token()
    expires_at = now + timedelta(minutes=settings.password_reset_token_expire_minutes)

    db.execute(
        update(models.PasswordResetToken)
        .where(
            models.PasswordResetToken.user_id == user.id,
            models.PasswordResetToken.used_at.is_(None),
        )
        .values(used_at=now)
    )

    reset_token = models.PasswordResetToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=expires_at,
    )
    db.add(reset_token)
    db.commit()

    reset_url = _build_reset_url(raw_token)

    try:
        send_password_reset_email(
            recipient_email=user.email,
            reset_url=reset_url,
            expires_minutes=settings.password_reset_token_expire_minutes,
        )
    except Exception:
        logger.exception("Failed to send password reset e-mail")

    if settings.expose_password_reset_link_in_response:
        response.debugResetLink = reset_url

    return response


@router.post("/reset-password", response_model=schemas.GenericMessageResponse)
def reset_password(
    payload: schemas.ResetPasswordRequest,
    db: Session = Depends(get_db),
) -> schemas.GenericMessageResponse:
    now = datetime.now(timezone.utc)
    token_hash = hash_reset_token(payload.token.strip())

    reset_token = db.execute(
        select(models.PasswordResetToken).where(
            models.PasswordResetToken.token_hash == token_hash,
            models.PasswordResetToken.used_at.is_(None),
            models.PasswordResetToken.expires_at > now,
        )
    ).scalar_one_or_none()

    if not reset_token:
        raise HTTPException(status_code=400, detail="Lien de reinitialisation invalide ou expire.")

    user = db.execute(select(models.User).where(models.User.id == reset_token.user_id)).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="Utilisateur introuvable.")

    password_error = validate_password_policy(
        payload.password,
        email=user.email,
        name=user.full_name,
    )
    if password_error:
        raise HTTPException(status_code=400, detail=password_error)

    user.password_hash = hash_password(payload.password)
    reset_token.used_at = now

    db.execute(
        update(models.PasswordResetToken)
        .where(
            models.PasswordResetToken.user_id == user.id,
            models.PasswordResetToken.used_at.is_(None),
            models.PasswordResetToken.id != reset_token.id,
        )
        .values(used_at=now)
    )

    db.add(user)
    db.add(reset_token)
    db.commit()

    return schemas.GenericMessageResponse(detail="Mot de passe mis a jour. Tu peux maintenant te connecter.")
