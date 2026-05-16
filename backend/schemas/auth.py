from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional


class RegisterRequest(BaseModel):
    full_name: str
    password: str
    email: Optional[str] = None
    phone_number: Optional[str] = None

    @field_validator("email", "phone_number", mode="before")
    @classmethod
    def at_least_one_identifier(cls, v):
        return v

    def model_post_init(self, __context):
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided")


class LoginRequest(BaseModel):
    identifier: str  # email or phone_number
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
