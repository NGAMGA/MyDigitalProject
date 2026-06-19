from collections.abc import Generator

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.config import settings


def _create_engine():
    # Allow lightweight local dev without Docker/PostgreSQL.
    if settings.database_url.startswith("sqlite"):
        return create_engine(
            settings.database_url,
            future=True,
            pool_pre_ping=True,
            connect_args={"check_same_thread": False},
        )

    return create_engine(settings.database_url, future=True, pool_pre_ping=True)


engine = _create_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
Base = declarative_base()


def ensure_schema_compatibility() -> None:
    inspector = inspect(engine)
    table_names = inspector.get_table_names()
    if "users" not in table_names:
        return

    user_columns = {column["name"] for column in inspector.get_columns("users")}
    missing_user_columns = {
        "first_name": "VARCHAR(80)",
        "last_name": "VARCHAR(80)",
        "phone_number": "VARCHAR(40)",
        "date_of_birth": "DATE",
        "country": "VARCHAR(80)",
        "bio": "TEXT",
        "avatar_data_url": "TEXT",
    }

    with engine.begin() as connection:
        for column_name, column_type in missing_user_columns.items():
            if column_name in user_columns:
                continue
            connection.execute(text(f"ALTER TABLE users ADD COLUMN {column_name} {column_type}"))

        if "subscriptions" not in table_names:
            return

        subscription_columns = {
            column["name"] for column in inspector.get_columns("subscriptions")
        }
        missing_subscription_columns = {
            "trial_end_date": "DATE",
            "stripe_customer_id": "VARCHAR(255)",
            "stripe_subscription_id": "VARCHAR(255)",
            "cancel_at_period_end": "BOOLEAN NOT NULL DEFAULT FALSE",
            "has_used_trial": "BOOLEAN NOT NULL DEFAULT FALSE",
        }
        for column_name, column_type in missing_subscription_columns.items():
            if column_name in subscription_columns:
                continue
            connection.execute(
                text(
                    f"ALTER TABLE subscriptions ADD COLUMN "
                    f"{column_name} {column_type}"
                )
            )


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
