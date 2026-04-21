from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.settings import Settings

_settings = Settings()

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=_settings.REDIS_URL or "memory://",
)
