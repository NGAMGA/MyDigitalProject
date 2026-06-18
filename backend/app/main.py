from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import Base, engine, ensure_schema_compatibility
from app.routers import (
    auth,
    food_filter,
    invoices,
    menus,
    shopping_lists,
    subscriptions,
    users,
)

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


FIELD_LABELS = {
    "name": "Nom complet",
    "email": "E-mail",
    "password": "Mot de passe",
    "token": "Token de reinitialisation",
    "currentPassword": "Mot de passe actuel",
    "nextPassword": "Nouveau mot de passe",
    "plan": "Plan",
    "status": "Statut",
    "renewal": "Date de renouvellement",
    "confirmPassword": "Confirmation du mot de passe",
    "firstName": "Prénom",
    "lastName": "Nom",
    "phoneNumber": "Téléphone",
    "dateOfBirth": "Date de naissance",
    "country": "Pays",
    "bio": "Bio",
    "avatarDataUrl": "Photo de profil",
    "items": "Liste de courses",
    "quantity": "Quantite",
    "category": "Categorie",
}


def _friendly_field_name(raw: str) -> str:
    return FIELD_LABELS.get(raw, raw)


def _translate_validation_error(item: dict) -> str:
    loc = item.get("loc") or []
    field = _friendly_field_name(str(loc[-1])) if loc else "Champ"
    err_type = str(item.get("type") or "")
    ctx = item.get("ctx") or {}
    msg = str(item.get("msg") or "")

    if err_type in {"missing", "value_error.missing"}:
        return f"{field}: champ requis."

    if err_type in {"string_too_short", "too_short"}:
        min_length = ctx.get("min_length")
        if min_length is not None:
            return f"{field}: minimum {min_length} caracteres."
        return f"{field}: texte trop court."

    if err_type in {"string_too_long", "too_long"}:
        max_length = ctx.get("max_length")
        if max_length is not None:
            return f"{field}: maximum {max_length} caracteres."
        return f"{field}: texte trop long."

    if "email" in err_type or "email" in msg.lower():
        return f"{field}: format invalide."

    if "date" in err_type or "date" in msg.lower():
        return f"{field}: date invalide (format attendu YYYY-MM-DD)."

    if msg:
        return f"{field}: {msg}"

    return f"{field}: valeur invalide."


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    _ = request
    messages = [_translate_validation_error(item) for item in exc.errors()]
    return JSONResponse(
        status_code=422,
        content={"detail": " | ".join(messages) if messages else "Donnees invalides."},
    )


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)
    ensure_schema_compatibility()


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(users.router, prefix=settings.api_prefix)
app.include_router(subscriptions.router, prefix=settings.api_prefix)
app.include_router(invoices.router, prefix=settings.api_prefix)
app.include_router(food_filter.router, prefix=settings.api_prefix)
app.include_router(menus.router, prefix=settings.api_prefix)
app.include_router(shopping_lists.router, prefix=settings.api_prefix)
