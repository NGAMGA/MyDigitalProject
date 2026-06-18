from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Komi API"
    api_prefix: str = "/api/v1"
    database_url: str = "postgresql+psycopg://komi:komi@localhost:5432/komi"
    jwt_secret_key: str = "change-this-secret-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24
    password_reset_token_expire_minutes: int = 30
    frontend_base_url: str = "http://127.0.0.1:4173"
    expose_password_reset_link_in_response: bool = True
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = "no-reply@komi.local"
    smtp_use_starttls: bool = True
    cors_origins: str = "*"
    stripe_secret_key: str = ""
    stripe_premium_price_id: str = ""
    stripe_success_url: str = "http://127.0.0.1:5454/#/subscription/success"
    stripe_cancel_url: str = "http://127.0.0.1:5454/#/subscription/cancel"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def cors_origins_list(self) -> list[str]:
        raw = self.cors_origins.strip()
        if not raw:
            return []
        if raw == "*":
            return ["*"]
        return [origin.strip() for origin in raw.split(",") if origin.strip()]


settings = Settings()
