from datetime import date

from app import models, schemas


def split_full_name(value: str | None) -> tuple[str, str]:
    parts = [part for part in str(value or "").strip().split() if part]
    if not parts:
        return "", ""
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], " ".join(parts[1:])


def join_full_name(first_name: str | None, last_name: str | None, fallback: str | None = None) -> str:
    combined = " ".join(part for part in [str(first_name or "").strip(), str(last_name or "").strip()] if part).strip()
    if combined:
        return combined
    return str(fallback or "").strip()


def format_renewal(value: date | None) -> str:
    if not value:
        return "-"
    return value.isoformat()


def format_optional_date(value: date | None) -> str:
    if not value:
        return ""
    return value.isoformat()


def serialize_subscription(subscription: models.Subscription | None) -> schemas.SubscriptionPublic:
    if subscription is None:
        return schemas.SubscriptionPublic(plan="Free", status="Actif", renewal="-")
    return schemas.SubscriptionPublic(
        plan=subscription.plan,
        status=subscription.status,
        renewal=format_renewal(subscription.renewal_date),
        trialEnd=format_renewal(subscription.trial_end_date),
        cancelAtPeriodEnd=subscription.cancel_at_period_end,
        stripeManaged=bool(subscription.stripe_subscription_id),
    )


def serialize_user(user: models.User, invoices_count: int = 0) -> schemas.UserPublic:
    derived_first_name, derived_last_name = split_full_name(user.full_name)

    return schemas.UserPublic(
        id=user.id,
        name=user.full_name,
        email=user.email,
        createdAt=user.created_at,
        profile=schemas.UserProfilePublic(
            firstName=(user.first_name or derived_first_name or "").strip(),
            lastName=(user.last_name or derived_last_name or "").strip(),
            phoneNumber=(user.phone_number or "").strip(),
            dateOfBirth=format_optional_date(user.date_of_birth),
            country=(user.country or "").strip(),
            bio=(user.bio or "").strip(),
            avatarDataUrl=(user.avatar_data_url or "").strip(),
        ),
        subscription=serialize_subscription(user.subscription),
        invoicesCount=invoices_count,
    )


def serialize_invoice(invoice: models.Invoice) -> schemas.InvoicePublic:
    return schemas.InvoicePublic(
        id=invoice.reference,
        date=invoice.issue_date.isoformat(),
        label=invoice.label,
        amount=f"{invoice.amount_cents / 100:.2f} EUR",
        status=invoice.status,
    )
