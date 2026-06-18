from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class SubscriptionPublic(BaseModel):
    plan: str
    status: str
    renewal: str = "-"


class SubscriptionPlanPublic(BaseModel):
    name: str
    label: str
    amountCents: int
    billingPeriod: str
    features: list[str]


class UserProfilePublic(BaseModel):
    firstName: str = ""
    lastName: str = ""
    phoneNumber: str = ""
    dateOfBirth: str = ""
    country: str = ""
    bio: str = ""
    avatarDataUrl: str = ""


class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    email: EmailStr
    createdAt: datetime
    profile: UserProfilePublic
    subscription: SubscriptionPublic
    invoicesCount: int = 0


class AuthRegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class AuthLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    detail: str
    debugResetLink: str | None = None


class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=20, max_length=300)
    password: str = Field(min_length=8, max_length=128)


class GenericMessageResponse(BaseModel):
    detail: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserPublic


class UpdateProfileRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    email: EmailStr | None = None
    firstName: str | None = Field(default=None, min_length=1, max_length=80)
    lastName: str | None = Field(default=None, min_length=1, max_length=80)
    phoneNumber: str | None = Field(default=None, min_length=1, max_length=40)
    dateOfBirth: date | None = None
    country: str | None = Field(default=None, min_length=1, max_length=80)
    bio: str | None = Field(default=None, max_length=1000)
    avatarDataUrl: str | None = Field(default=None, max_length=2000000)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(alias="currentPassword", min_length=1, max_length=128)
    next_password: str = Field(alias="nextPassword", min_length=8, max_length=128)

    model_config = ConfigDict(populate_by_name=True)


class SubscriptionUpdateRequest(BaseModel):
    plan: Literal["Free", "Premium", "Pro"]
    status: Literal["Actif", "Annule", "Expire", "En pause"] = "Actif"
    renewal: date | None = None


class CheckoutSessionPublic(BaseModel):
    url: str


class InvoicePublic(BaseModel):
    id: str
    date: str
    label: str
    amount: str
    status: str


class ShoppingListItem(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    quantity: str | None = Field(default=None, max_length=80)
    category: str | None = Field(default=None, max_length=80)

    @field_validator("name", "quantity", "category", mode="before")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return str(value).strip()


class FoodFilterRequest(BaseModel):
    items: list[str | ShoppingListItem] = Field(min_length=1, max_length=300)


class FoodFilterItemPublic(BaseModel):
    name: str
    quantity: str = ""
    category: str = ""
    confidence: float = Field(ge=0, le=1)
    matchedTerms: list[str] = Field(default_factory=list)


class FoodFilterRejectedItemPublic(BaseModel):
    name: str
    quantity: str = ""
    category: str = ""
    reason: str
    matchedTerms: list[str] = Field(default_factory=list)


class FoodFilterResponse(BaseModel):
    foodItems: list[FoodFilterItemPublic]
    rejectedItems: list[FoodFilterRejectedItemPublic]
    totalItems: int
    foodCount: int
    rejectedCount: int


class ShoppingListAnalysisItem(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    confidence: float = Field(ge=0, le=1)


class ShoppingListRejectedItem(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    reason: str = "Produit non alimentaire ignore"


class ShoppingListAnalysisResponse(BaseModel):
    source: str
    rawText: str
    items: list[ShoppingListAnalysisItem]
    rejectedItems: list[ShoppingListRejectedItem] = Field(default_factory=list)


class ShoppingListValidateRequest(BaseModel):
    items: list[str] = Field(min_length=1, max_length=80)
