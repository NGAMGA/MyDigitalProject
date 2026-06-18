from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session, joinedload

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user
from app.food_filter import classify_food_items, normalize_food_text
from app.shopping_list_ocr import analyze_shopping_list_image

router = APIRouter(prefix="/shopping-lists", tags=["shopping-lists"])


def _is_premium(user: models.User) -> bool:
    subscription = user.subscription
    return bool(
        subscription
        and subscription.plan in {"Premium", "Pro"}
        and subscription.status == "Actif"
    )


def _active_list(user_id: str, db: Session) -> models.ShoppingList | None:
    return db.execute(
        select(models.ShoppingList)
        .options(joinedload(models.ShoppingList.items).joinedload(models.ShoppingListProduct.product))
        .where(
            models.ShoppingList.user_id == user_id,
            models.ShoppingList.is_active.is_(True),
        )
        .order_by(models.ShoppingList.updated_at.desc())
    ).unique().scalars().first()


def _ensure_active_list(user_id: str, db: Session) -> models.ShoppingList:
    shopping_list = _active_list(user_id, db)
    if shopping_list is not None:
        return shopping_list
    shopping_list = models.ShoppingList(user_id=user_id)
    db.add(shopping_list)
    db.commit()
    return _active_list(user_id, db) or shopping_list


def _serialize_list(shopping_list: models.ShoppingList) -> schemas.ShoppingListPublic:
    return schemas.ShoppingListPublic(
        id=shopping_list.id,
        name=shopping_list.name,
        isActive=shopping_list.is_active,
        createdAt=shopping_list.created_at,
        updatedAt=shopping_list.updated_at,
        items=[
            schemas.ShoppingProductPublic(
                id=link.id,
                name=link.product.name,
                brand=link.product.brand,
                quantity=link.quantity,
                imageUrl=link.product.image_url,
                energyKcal=link.product.energy_kcal,
                proteins=link.product.proteins,
                fibers=link.product.fibers,
                fat=link.product.fat,
                sugars=link.product.sugars,
                salt=link.product.salt,
                nutriScore=link.product.nutri_score,
            )
            for link in shopping_list.items
        ],
    )


@router.get("/current", response_model=schemas.ShoppingListPublic)
def get_current_list(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.ShoppingListPublic:
    return _serialize_list(_ensure_active_list(current_user.id, db))


@router.get("/history", response_model=list[schemas.ShoppingListPublic])
def get_list_history(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[schemas.ShoppingListPublic]:
    if not _is_premium(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="L historique complet des listes est reserve au plan Premium.",
        )
    lists = db.execute(
        select(models.ShoppingList)
        .options(joinedload(models.ShoppingList.items).joinedload(models.ShoppingListProduct.product))
        .where(models.ShoppingList.user_id == current_user.id)
        .order_by(models.ShoppingList.updated_at.desc())
    ).unique().scalars().all()
    return [_serialize_list(item) for item in lists]


@router.post("", response_model=schemas.ShoppingListPublic)
def create_new_list(
    payload: schemas.ShoppingListCreateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.ShoppingListPublic:
    current = _active_list(current_user.id, db)
    if current is not None:
        if _is_premium(current_user):
            current.is_active = False
        else:
            db.delete(current)
        db.flush()
    shopping_list = models.ShoppingList(user_id=current_user.id, name=payload.name)
    db.add(shopping_list)
    db.commit()
    return _serialize_list(_active_list(current_user.id, db) or shopping_list)


@router.put("/current/items", response_model=schemas.ShoppingListPublic)
def replace_current_items(
    payload: schemas.ShoppingListReplaceItemsRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.ShoppingListPublic:
    shopping_list = _ensure_active_list(current_user.id, db)
    db.execute(
        delete(models.ShoppingListProduct).where(
            models.ShoppingListProduct.shopping_list_id == shopping_list.id
        )
    )

    for item in payload.items:
        normalized_name = normalize_food_text(item.name)
        product = db.execute(
            select(models.Product).where(models.Product.normalized_name == normalized_name)
        ).scalar_one_or_none()
        if product is None:
            product = models.Product(
                normalized_name=normalized_name,
                name=item.name,
                brand=item.brand,
                image_url=item.imageUrl,
                energy_kcal=item.energyKcal,
                proteins=item.proteins,
                fibers=item.fibers,
                fat=item.fat,
                sugars=item.sugars,
                salt=item.salt,
                nutri_score=item.nutriScore,
            )
            db.add(product)
            db.flush()
        db.add(
            models.ShoppingListProduct(
                shopping_list_id=shopping_list.id,
                product_id=product.id,
                quantity=item.quantity,
                is_food=True,
            )
        )
    db.commit()
    return _serialize_list(_active_list(current_user.id, db) or shopping_list)


@router.delete("/current/items/{item_id}", response_model=schemas.ShoppingListPublic)
def remove_current_item(
    item_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.ShoppingListPublic:
    shopping_list = _ensure_active_list(current_user.id, db)
    link = db.get(models.ShoppingListProduct, item_id)
    if link is None or link.shopping_list_id != shopping_list.id:
        raise HTTPException(status_code=404, detail="Produit introuvable dans cette liste.")
    db.delete(link)
    db.commit()
    return _serialize_list(_active_list(current_user.id, db) or shopping_list)


@router.delete("/current", response_model=schemas.ShoppingListPublic)
def clear_current_list(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.ShoppingListPublic:
    shopping_list = _ensure_active_list(current_user.id, db)
    db.execute(
        delete(models.ShoppingListProduct).where(
            models.ShoppingListProduct.shopping_list_id == shopping_list.id
        )
    )
    db.commit()
    return _serialize_list(_active_list(current_user.id, db) or shopping_list)


@router.post(
    "/analyze-image",
    response_model=schemas.ShoppingListAnalysisResponse,
)
async def analyze_image(
    image: UploadFile = File(...),
    source: str = "gallery",
    current_user: models.User = Depends(get_current_user),
) -> schemas.ShoppingListAnalysisResponse:
    _ = current_user

    content_type = (image.content_type or "").lower()
    allowed_content_type = not content_type or content_type.startswith("image/")
    allowed_extension = (image.filename or "").lower().endswith(
        (".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif")
    )
    if not allowed_content_type and not allowed_extension:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier envoye doit etre une image.",
        )

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image vide ou illisible.",
        )
    if not _looks_like_image(image_bytes):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier envoye doit etre une image lisible.",
        )

    try:
        result = analyze_shopping_list_image(image_bytes)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Impossible d analyser cette image de liste.",
        ) from exc

    accepted, rejected = classify_food_items([item.name for item in result.items])

    return schemas.ShoppingListAnalysisResponse(
        source=source,
        rawText=result.raw_text,
        items=[
            schemas.ShoppingListAnalysisItem(
                name=name,
                confidence=_confidence_for_item(name, result.items),
            )
            for name in accepted
        ],
        rejectedItems=[
            schemas.ShoppingListRejectedItem(name=name)
            for name in rejected
        ],
    )


@router.post(
    "/validate-items",
    response_model=schemas.ShoppingListAnalysisResponse,
)
def validate_items(
    payload: schemas.ShoppingListValidateRequest,
    current_user: models.User = Depends(get_current_user),
) -> schemas.ShoppingListAnalysisResponse:
    _ = current_user
    accepted, rejected = classify_food_items(payload.items)

    return schemas.ShoppingListAnalysisResponse(
        source="manual",
        rawText="\n".join(payload.items),
        items=[
            schemas.ShoppingListAnalysisItem(name=name, confidence=1)
            for name in accepted
        ],
        rejectedItems=[
            schemas.ShoppingListRejectedItem(name=name)
            for name in rejected
        ],
    )


def _confidence_for_item(name: str, items: list) -> float:
    normalized_name = name.casefold()
    for item in items:
        if item.name.casefold() == normalized_name:
            return round(item.confidence, 3)
    return 1


def _looks_like_image(content: bytes) -> bool:
    signatures = (
        b"\xff\xd8\xff",
        b"\x89PNG\r\n\x1a\n",
        b"RIFF",
        b"\x00\x00\x00",
    )
    return any(content.startswith(signature) for signature in signatures)
