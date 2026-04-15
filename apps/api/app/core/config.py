from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    app_name: str = "Nexo API"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    database_url: str = f"sqlite:///{(BASE_DIR / 'nexo.db').as_posix()}"
    backup_dir: str = str(BASE_DIR / "backups")
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]
    default_workspace_name: str = "Nexo"
    default_currency: str = "BRL"
    default_timezone: str = "America/Sao_Paulo"
    default_partner_name: str = "Daniel"
    default_partner_percent: float = 30.0

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()
