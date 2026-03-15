"""GardNx Backend - AI-powered garden planning API."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.models.schemas import HealthResponse
from app.services.garden_analyzer import GardenAnalyzer

logger = logging.getLogger("gardnx")

# Global state
app_state: dict = {
    "model": None,
    "model_loaded": False,
    "mock_mode": settings.use_mock_model,
    "firebase_initialized": False,
}


def _init_firebase() -> None:
    """Initialize Firebase Admin SDK if credentials are available."""
    try:
        import firebase_admin
        from firebase_admin import credentials

        if firebase_admin._apps:
            logger.info("Firebase already initialized")
            app_state["firebase_initialized"] = True
            return

        creds_path = settings.firebase_creds_path
        if creds_path.exists():
            cred = credentials.Certificate(str(creds_path))
            firebase_admin.initialize_app(
                cred,
                {"storageBucket": settings.firebase_storage_bucket},
            )
            app_state["firebase_initialized"] = True
            logger.info("Firebase initialized successfully")
        else:
            logger.warning(
                "Firebase credentials not found at %s. "
                "Firebase features will be unavailable.",
                creds_path,
            )
    except Exception as e:
        logger.warning("Firebase initialization failed: %s", e)


def _load_model() -> None:
    """Load the ML model or initialize mock mode."""
    analyzer = GardenAnalyzer(
        weights_path=str(settings.weights_path),
        use_mock=settings.use_mock_model,
        hf_api_token=settings.hf_api_token,
    )
    analyzer.load_model()
    app_state["model"] = analyzer
    app_state["model_loaded"] = True
    app_state["mock_mode"] = settings.use_mock_model

    if settings.use_mock_model:
        logger.info("Garden analyzer initialized in MOCK mode")
    else:
        logger.info("Garden analyzer initialized with real model weights")


@asynccontextmanager
async def lifespan(application: FastAPI):
    """Startup and shutdown logic."""
    logging.basicConfig(
        level=logging.DEBUG if settings.debug else logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    logger.info("Starting GardNx Backend...")

    # Initialize Firebase
    _init_firebase()

    # Load ML model
    _load_model()

    logger.info("GardNx Backend started successfully")
    yield

    # Cleanup
    logger.info("Shutting down GardNx Backend...")
    app_state["model"] = None
    app_state["model_loaded"] = False


app = FastAPI(
    title="GardNx API",
    description="AI-powered garden planning backend for Mauritius",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
from app.api.v1.router import v1_router  # noqa: E402

app.include_router(v1_router, prefix="/api/v1")


@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse(
        status="ok",
        model_loaded=app_state["model_loaded"],
        mock_mode=app_state["mock_mode"],
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
