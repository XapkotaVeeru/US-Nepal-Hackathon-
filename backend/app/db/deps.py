from collections.abc import Generator

from sqlmodel import Session

from app.db.session import get_session


def session_dependency() -> Generator[Session, None, None]:
    yield from get_session()
