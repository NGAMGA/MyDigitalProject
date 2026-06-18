from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app import models, schemas
from app.deps import get_current_user
from app.food_filter import classify_food_items
from app.shopping_list_ocr import analyze_shopping_list_image

router = APIRouter(prefix="/shopping-lists", tags=["shopping-lists"])


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
