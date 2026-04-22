from datetime import UTC, datetime, timedelta

from jwt import DecodeError, ExpiredSignatureError, decode, encode
from pwdlib import PasswordHash

from app.core.settings import Settings

settings = Settings()
pwd_context = PasswordHash.recommended()


def create_access_token(user_id: int, tenant_id: int, role: str) -> str:
    expire = datetime.now(UTC) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    to_encode = {
        "sub": str(user_id),
        "tenant_id": tenant_id,
        "role": role,
        "exp": expire,
        "type": "access",
    }
    return encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(user_id: int) -> str:
    expire = datetime.now(UTC) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    to_encode = {"sub": str(user_id), "exp": expire, "type": "refresh"}
    return encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_admin_access_token(admin_id: int, username: str) -> str:
    expire = datetime.now(UTC) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    to_encode = {
        "sub": str(admin_id),
        "username": username,
        "exp": expire,
        "type": "admin_access",
    }
    return encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_temp_2fa_token(admin_id: int) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=5)
    return encode(
        {"sub": f"temp_2fa:{admin_id}", "type": "temp_2fa", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_invite_token(email: str) -> str:
    expire = datetime.now(UTC) + timedelta(hours=48)
    return encode(
        {"sub": email, "type": "invite", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_password_reset_token(email: str) -> str:
    expire = datetime.now(UTC) + timedelta(hours=1)
    return encode(
        {"sub": email, "type": "password_reset", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def decode_token(token: str) -> dict:
    try:
        return decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except (DecodeError, ExpiredSignatureError):
        return {}


def decode_temp_2fa_token(token: str) -> int | None:
    payload = decode_token(token)
    if payload.get("type") == "temp_2fa":
        sub = payload.get("sub", "")
        if sub.startswith("temp_2fa:"):
            return int(sub.split(":")[1])
    return None


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)
