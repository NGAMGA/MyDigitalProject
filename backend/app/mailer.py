import smtplib
from email.message import EmailMessage

from app.config import settings


def send_password_reset_email(recipient_email: str, reset_url: str, expires_minutes: int) -> bool:
    if not settings.smtp_host.strip():
        return False

    message = EmailMessage()
    message["Subject"] = "Komi - Reinitialisation du mot de passe"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient_email
    message.set_content(
        "\n".join(
            [
                "Bonjour,",
                "",
                "Tu as demande la reinitialisation de ton mot de passe Komi.",
                f"Clique sur ce lien (valable {expires_minutes} minutes) :",
                reset_url,
                "",
                "Si tu n'es pas a l'origine de cette demande, ignore simplement ce message.",
                "",
                "Equipe Komi",
            ]
        )
    )

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
        if settings.smtp_use_starttls:
            smtp.starttls()
        if settings.smtp_username.strip():
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)

    return True
