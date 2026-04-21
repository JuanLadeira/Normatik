from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.crypto import EncryptedString
from app.core.database import Base


class Admin(Base):
    __tablename__ = "admins"

    username: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    email: Mapped[str] = mapped_column(
        String(254), unique=True, index=True, nullable=False
    )
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    totp_secret: Mapped[str | None] = mapped_column(EncryptedString(700), nullable=True)
    totp_habilitado: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
