import io
import re
from dataclasses import dataclass

import numpy as np
from PIL import Image, ImageFilter, ImageOps
from rapidocr_onnxruntime import RapidOCR

from app.food_filter import classify_food_items


_ocr_engine = RapidOCR()

_line_splitter = re.compile(r"[\n,;|]+")
_multi_space = re.compile(r"\s+")
_leading_markers = re.compile(r"^[\-\*\u2022\[\]\(\)_~.]+")
_leading_quantity = re.compile(
    r"^(?:\d+\s*(?:x|X)?\s+|\d+\s*(?:kg|g|gr|l|cl|ml)\s+)",
)
_trailing_noise = re.compile(r"[\-_*~.,;:]+$")
_disallowed_exact = {
    "liste",
    "courses",
    "liste de courses",
    "ma liste",
}


@dataclass(frozen=True)
class OcrItem:
    name: str
    confidence: float


@dataclass(frozen=True)
class OcrAnalysisResult:
    raw_text: str
    items: list[OcrItem]


def analyze_shopping_list_image(image_bytes: bytes) -> OcrAnalysisResult:
    candidates = [
        _analyze_prepared_image(image_array)
        for image_array in _prepare_image_variants(image_bytes)
    ]
    return max(candidates, key=_analysis_score, default=OcrAnalysisResult(raw_text="", items=[]))


def _analyze_prepared_image(image_array: np.ndarray) -> OcrAnalysisResult:
    result, _ = _ocr_engine(image_array)
    if not result:
        return OcrAnalysisResult(raw_text="", items=[])

    sorted_result = sorted(result, key=_ocr_sort_key)
    raw_lines = []
    parsed_items: list[OcrItem] = []
    seen: set[str] = set()

    for entry in sorted_result:
        text = str(entry[1]).strip() if len(entry) > 1 else ""
        confidence = float(entry[2]) if len(entry) > 2 else 0.0
        if not text:
            continue

        raw_lines.append(text)
        for candidate in _extract_candidates(text):
            normalized = candidate.casefold()
            if normalized in seen:
                continue
            seen.add(normalized)
            parsed_items.append(OcrItem(name=candidate, confidence=confidence))

    return OcrAnalysisResult(
        raw_text="\n".join(raw_lines),
        items=parsed_items,
    )


def _prepare_image_variants(image_bytes: bytes) -> list[np.ndarray]:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    max_width = 1800
    if image.width > max_width:
        ratio = max_width / image.width
        image = image.resize(
            (max_width, int(image.height * ratio)),
            Image.Resampling.LANCZOS,
        )

    grayscale = ImageOps.grayscale(image)
    contrasted = ImageOps.autocontrast(grayscale)
    sharpened = contrasted.filter(ImageFilter.SHARPEN)
    binary = contrasted.point(lambda pixel: 255 if pixel > 150 else 0)
    inverted_binary = ImageOps.invert(binary)

    return [
        np.array(image),
        np.array(contrasted),
        np.array(sharpened),
        np.array(binary),
        np.array(inverted_binary),
    ]


def _analysis_score(result: OcrAnalysisResult) -> tuple[int, float, int]:
    accepted, _ = classify_food_items([item.name for item in result.items])
    confidence_sum = sum(item.confidence for item in result.items)
    return (len(accepted), confidence_sum, len(result.raw_text))


def _ocr_sort_key(entry: list) -> tuple[float, float]:
    box = entry[0] if entry else []
    if not box:
        return (0, 0)

    y_values = [float(point[1]) for point in box if len(point) > 1]
    x_values = [float(point[0]) for point in box if point]
    return (
        sum(y_values) / len(y_values) if y_values else 0,
        sum(x_values) / len(x_values) if x_values else 0,
    )


def _extract_candidates(text: str) -> list[str]:
    candidates = []

    for raw_part in _line_splitter.split(text):
        cleaned = _clean_candidate(raw_part)
        if cleaned is None:
            continue
        candidates.append(cleaned)

    return candidates


def _clean_candidate(value: str) -> str | None:
    candidate = value.strip()
    candidate = _leading_markers.sub("", candidate).strip()
    candidate = _leading_quantity.sub("", candidate).strip()
    candidate = _trailing_noise.sub("", candidate).strip()
    candidate = _multi_space.sub(" ", candidate)

    if len(candidate) < 2:
        return None
    if candidate.casefold() in _disallowed_exact:
        return None
    if not re.search(r"[A-Za-zÀ-ÿ]", candidate):
        return None
    if re.fullmatch(r"[\d\s]+", candidate):
        return None

    return candidate[0].upper() + candidate[1:]
