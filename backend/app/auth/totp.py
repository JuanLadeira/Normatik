import pyotp


def gerar_secret() -> str:
    return pyotp.random_base32()


def gerar_qr_uri(secret: str, username: str, issuer: str = "Normatiq") -> str:
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=username, issuer_name=issuer)


def verificar_codigo(secret: str, codigo: str) -> bool:
    totp = pyotp.TOTP(secret)
    return totp.verify(codigo, valid_window=1)
