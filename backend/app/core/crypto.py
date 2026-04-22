"""
Criptografia de campos sensíveis com Fernet (AES-128-CBC + HMAC-SHA256).

Gerar chave: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

Se ENCRYPTION_KEY não estiver configurada, valores são salvos em plaintext —
adequado para desenvolvimento. Em produção é obrigatório.
"""

import logging
import os

from sqlalchemy import String
from sqlalchemy.types import TypeDecorator

_log = logging.getLogger(__name__)
_FERNET_KEY = os.getenv("ENCRYPTION_KEY", "")
_fernet = None

if _FERNET_KEY:
    from cryptography.fernet import Fernet

    _fernet = Fernet(_FERNET_KEY.encode())
else:
    _log.warning(
        "ENCRYPTION_KEY não configurada — secrets salvos em plaintext. "
        "Configure em produção."
    )


def encrypt(value: str) -> str:
    if _fernet is None:
        return value
    return _fernet.encrypt(value.encode()).decode()


def decrypt(value: str) -> str:
    if _fernet is None:
        return value
    try:
        return _fernet.decrypt(value.encode()).decode()
    except Exception:
        return value  # plaintext legado


class EncryptedString(TypeDecorator):
    """
    TypeDecorator que criptografa ao gravar e descriptografa ao ler.

    Uso: secret: Mapped[str | None] = mapped_column(EncryptedString(700), nullable=True)
    O tamanho (700) é para a string criptografada no banco (~1.37× o plaintext).
    """

    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        return encrypt(value) if value is not None else value

    def process_result_value(self, value, dialect):
        return decrypt(value) if value is not None else value
