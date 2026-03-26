"""Application configuration using pydantic-settings."""

from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables and .env file."""

    firebase_credentials_path: str = "./firebase-credentials.json"
    firebase_storage_bucket: str = "gardnx-app.appspot.com"
    model_weights_path: str = "./app/ml/weights/deeplabv3_garden.pth"
    use_mock_model: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = True
    open_meteo_base_url: str = "https://archive-api.open-meteo.com/v1/archive"
    perenual_api_key: str = ""
    gemini_api_key: str = ""
    hf_api_token: str = ""

    @property
    def weights_path(self) -> Path:
        return Path(self.model_weights_path)

    @property
    def firebase_creds_path(self) -> Path:
        return Path(self.firebase_credentials_path)

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
        "protected_namespaces": ("settings_",),
    }


settings = Settings()
