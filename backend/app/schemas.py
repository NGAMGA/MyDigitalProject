from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class SubscriptionPublic(BaseModel):
    plan: str
    status: str
    renewal: str = "-"


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
    plan: str = Field(min_length=1, max_length=30)
    status: str = Field(min_length=1, max_length=30)
    renewal: date | None = None


class InvoicePublic(BaseModel):
    id: str
    date: str
    label: str
    amount: str
    status: str
