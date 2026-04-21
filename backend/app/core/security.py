from datetime import datetime, timedelta, timezone

from jwt import decode, encode, DecodeError, ExpiredSignatureError
from pwdlib import PasswordHash

from app.core.settings import Settings

settings = Settings()
_pwd = PasswordHash.recommended()


def get_password_hash(password: str) -> str:
    return _pwd.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd.verify(plain, hashed)


def create_access_token(user_id: int, tenant_id: int, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    return encode(
        {"sub": str(user_id), "tenant_id": tenant_id, "role": role, "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_refresh_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    return encode(
        {"sub": str(user_id), "type": "refresh", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_admin_access_token(admin_id: int, username: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    return encode(
        {"sub": f"admin:{username}", "admin_id": admin_id, "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_temp_2fa_token(admin_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=5)
    return encode(
        {"sub": f"temp_2fa:{admin_id}", "type": "temp_2fa", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_invite_token(email: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=48)
    return encode(
        {"sub": email, "type": "invite", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_password_reset_token(email: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=1)
    return encode(
        {"sub": email, "type": "password_reset", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def _decode(token: str) -> dict | None:
    try:
        return decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except (DecodeError, ExpiredSignatureError):
        return None


def decode_access_token(token: str) -> dict | None:
    payload = _decode(token)
    if payload and "tenant_id" in payload:
        return payload
    return None


def decode_admin_token(token: str) -> dict | None:
    payload = _decode(token)
    if payload and payload.get("sub", "").startswith("admin:"):
        return payload
    return None


def decode_temp_2fa_token(token: str) -> int | None:
    payload = _decode(token)
    if not payload or payload.get("type") != "temp_2fa":
        return None
    sub = payload.get("sub", "")
    if not sub.startswith("temp_2fa:"):
        return None
    try:
        return int(sub.split(":")[1])
    except ValueError:
        return None


def decode_invite_token(token: str) -> str | None:
    payload = _decode(token)
    if payload and payload.get("type") == "invite":
        return payload.get("sub")
    return None


def decode_password_reset_token(token: str) -> str | None:
    payload = _decode(token)
    if payload and payload.get("type") == "password_reset":
        return payload.get("sub")
    return None
