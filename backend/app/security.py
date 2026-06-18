import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

PASSWORD_DENY_LIST = {
    "password",
    "password123",
    "12345678",
    "123456789",
    "1234567890",
    "azerty123",
    "qwerty123",
    "admin123",
    "letmein123",
    "komi1234",
}


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def hash_reset_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_password_reset_token() -> tuple[str, str]:
    raw_token = secrets.token_urlsafe(48)
    token_hash = hash_reset_token(raw_token)
    return raw_token, token_hash


def sanitize_token(value: str) -> str:
    return "".join(ch for ch in value.lower() if ch.isalnum())


def validate_password_policy(password: str, email: str | None = None, name: str | None = None) -> str | None:
    if len(password) < 8:
        return "Le mot de passe doit contenir au moins 8 caracteres."
    if len(password) > 128:
        return "Le mot de passe ne doit pas depasser 128 caracteres."
    if not any(ch.islower() for ch in password):
        return "Le mot de passe doit contenir au moins une lettre minuscule."
    if not any(ch.isupper() for ch in password):
        return "Le mot de passe doit contenir au moins une lettre majuscule."
    if not any(ch.isdigit() for ch in password):
        return "Le mot de passe doit contenir au moins un chiffre."
    if all(ch.isalnum() for ch in password):
        return "Le mot de passe doit contenir au moins un caractere special."

    lowered = password.lower()
    if lowered in PASSWORD_DENY_LIST:
        return "Ce mot de passe est trop commun, choisis-en un autre."

    cleaned_password = sanitize_token(password)
    if email:
        local_part = sanitize_token(email.split("@")[0])
        if len(local_part) >= 3 and local_part in cleaned_password:
            return "Le mot de passe ne doit pas contenir ton e-mail."

    if name:
        tokens = [sanitize_token(part) for part in name.split()]
        for token in tokens:
            if len(token) >= 3 and token in cleaned_password:
                return "Le mot de passe ne doit pas contenir ton nom."

    return None


def create_access_token(subject: str) -> str:
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {"sub": subject, "exp": expires_at}
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
