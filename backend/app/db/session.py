from sqlalchemy import inspect, text
from sqlmodel import Session, SQLModel, create_engine

from app.core.config import get_settings


settings = get_settings()

connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}
engine = create_engine(settings.database_url, echo=settings.debug, connect_args=connect_args)


def get_session() -> Session:
    with Session(engine) as session:
        yield session


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)
    _apply_legacy_schema_updates()


def _apply_legacy_schema_updates() -> None:
    inspector = inspect(engine)
    if "anonymoususer" not in inspector.get_table_names():
        return

    existing_columns = {
        column["name"] for column in inspector.get_columns("anonymoususer")
    }
    column_statements = {
        "notifications_enabled": (
            "ALTER TABLE anonymoususer "
            "ADD COLUMN notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE"
        ),
        "sound_enabled": (
            "ALTER TABLE anonymoususer "
            "ADD COLUMN sound_enabled BOOLEAN NOT NULL DEFAULT TRUE"
        ),
        "chat_requests_enabled": (
            "ALTER TABLE anonymoususer "
            "ADD COLUMN chat_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE"
        ),
        "group_invites_enabled": (
            "ALTER TABLE anonymoususer "
            "ADD COLUMN group_invites_enabled BOOLEAN NOT NULL DEFAULT TRUE"
        ),
    }

    with engine.begin() as connection:
        for column_name, statement in column_statements.items():
            if column_name not in existing_columns:
                connection.execute(text(statement))
