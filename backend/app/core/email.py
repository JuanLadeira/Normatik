import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import logging
from app.core.settings import settings

logger = logging.getLogger("email")


class EmailService:
    def _get_base_template(self, content: str) -> str:
        """Retorna o invólucro HTML padrão para todos os e-mails do sistema."""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #F1F4F8; color: #334155; }}
                .wrapper {{ width: 100%; table-layout: fixed; background-color: #F1F4F8; padding-bottom: 40px; }}
                .main {{ background-color: #ffffff; width: 100%; max-width: 600px; margin: 0 auto; border-radius: 8px; overflow: hidden; border: 1px solid #E2E8F0; margin-top: 40px; }}
                .header {{ background-color: #1A3A6C; padding: 32px; text-align: center; }}
                .logo-text {{ color: #ffffff; font-size: 24px; font-weight: bold; letter-spacing: -0.5px; margin: 0; }}
                .logo-bar {{ display: inline-block; width: 4px; border-radius: 1px; margin: 0 1px; }}
                .content {{ padding: 40px 32px; line-height: 1.6; }}
                .footer {{ text-align: center; padding: 20px; font-size: 12px; color: #94A3B8; }}
                .button {{ display: inline-block; padding: 14px 32px; background-color: #00B5A4; color: #ffffff !important; text-decoration: none; border-radius: 6px; font-weight: 600; margin-top: 24px; }}
                h1 {{ color: #0F172A; font-size: 20px; margin-top: 0; }}
                p {{ margin-bottom: 16px; }}
            </style>
        </head>
        <body>
            <div class="wrapper">
                <div class="main">
                    <div class="header">
                        <div style="display: inline-block; vertical-align: middle; margin-right: 10px;">
                            <div class="logo-bar" style="background:#00B5A4;height:12px"></div>
                            <div class="logo-bar" style="background:#00B5A4;height:18px"></div>
                            <div class="logo-bar" style="background:#ffffff;height:8px;opacity:0.6"></div>
                        </div>
                        <span class="logo-text">Normatiq</span>
                    </div>
                    <div class="content">
                        {content}
                    </div>
                </div>
                <div class="footer">
                    &copy; 2026 Normatiq — Gestão Inteligente para Metrologia<br>
                    Este é um e-mail automático, por favor não responda.
                </div>
            </div>
        </body>
        </html>
        """

    def send_email(self, to_email: str, subject: str, html_content: str):
        """Envia um e-mail via SMTP configurado."""
        if not settings.SMTP_HOST:
            logger.warning(f"SMTP não configurado. E-mail para {to_email} ignorado.")
            return

        msg = MIMEMultipart()
        msg["From"] = f"Normatiq <{settings.EMAIL_FROM}>"
        msg["To"] = to_email
        msg["Subject"] = subject
        msg.attach(MIMEText(html_content, "html"))

        try:
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                if settings.SMTP_USER:
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.send_message(msg)
            logger.info(f"E-mail enviado com sucesso para {to_email}")
        except Exception as e:
            logger.error(f"Erro ao enviar e-mail para {to_email}: {e}")
            raise e

    def send_user_invite(self, email: str, nome: str, token: str):
        """Prepara e envia o e-mail de convite com o novo template."""
        invite_url = f"{settings.FRONTEND_URL}/accept-invite?token={token}"

        subject = "Bem-vindo ao Normatiq — Convite para Colaborador"

        content = f"""
            <h1>Olá, {nome}!</h1>
            <p>Você foi convidado para colaborar no laboratório <strong>{settings.OWNER_TENANT_NAME}</strong>.</p>
            <p>O Normatiq é a sua nova plataforma para gestão de calibrações e conformidade técnica.</p>
            <p>Para ativar sua conta e definir sua senha de acesso, clique no botão abaixo:</p>
            <div style="text-align: center;">
                <a href="{invite_url}" class="button">Ativar Minha Conta</a>
            </div>
            <p style="margin-top: 32px; font-size: 13px; color: #64748B;">
                <strong>Nota:</strong> Este convite é válido por 48 horas. Se o botão acima não funcionar, copie e cole o link no seu navegador:<br>
                <span style="word-break: break-all; color: #1A3A6C;">{invite_url}</span>
            </p>
        """

        html = self._get_base_template(content)
        self.send_email(email, subject, html)


email_service = EmailService()
