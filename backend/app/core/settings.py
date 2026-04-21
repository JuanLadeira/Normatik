from zoneinfo import ZoneInfo
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

TIMEZONE = ZoneInfo("America/Sao_Paulo")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Project
    PROJECT_NAME: str = "Normatik"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://normatik:normatik@localhost:5432/normatik",
    )

    # JWT
    SECRET_KEY: str = Field(default="insecure-dev-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Admin padrão (seed)
    ADMIN_DEFAULT_USERNAME: str = "admin"
    ADMIN_DEFAULT_PASSWORD: str = "admin"

    # Criptografia de campos sensíveis (Fernet)
    ENCRYPTION_KEY: str = Field(default="")

    # Redis (Celery broker + rate limit)
    REDIS_URL: str = Field(default="redis://localhost:6379/0")

    # E-mail (Mailpit em dev, SMTP real em prod)
    SMTP_HOST: str = "localhost"
    SMTP_PORT: int = 1025
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    EMAIL_FROM: str = "noreply@normatiq.com.br"

    # Storage S3 / MinIO
    S3_ENDPOINT_URL: str = "http://localhost:9000"
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_BUCKET: str = "normatik"
    S3_REGION: str = "us-east-1"

    # Trial padrão (dias)
    DEFAULT_TRIAL_DAYS: int = 30

    # Frontend
    FRONTEND_URL: str = "http://localhost:3000"


settings = Settings()
