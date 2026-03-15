"""Shared dependencies for API endpoints."""

from fastapi import Depends, HTTPException, Header
from typing import Optional

import logging

logger = logging.getLogger("gardnx")


async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """Verify Firebase ID token and return user_id.

    If no authorization header is provided, returns 'anonymous' for
    development purposes. In production, this should always require
    a valid Bearer token.
    """
    if not authorization or not authorization.startswith("Bearer "):
        # In development/mock mode, allow anonymous access
        logger.debug("No authorization header; using anonymous user")
        return "anonymous"

    token = authorization.split("Bearer ")[1]
    try:
        import firebase_admin
        from firebase_admin import auth as firebase_auth

        # If Firebase wasn't initialized (no credentials file), skip verification
        if not firebase_admin._apps:
            logger.warning("Firebase not initialized; accepting token as-is for dev")
            # Decode the JWT payload without verification to extract uid
            import base64, json
            payload_b64 = token.split(".")[1]
            # Add padding
            payload_b64 += "=" * (4 - len(payload_b64) % 4)
            payload = json.loads(base64.urlsafe_b64decode(payload_b64))
            return payload.get("user_id") or payload.get("sub") or "anonymous"

        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token["uid"]
    except ImportError:
        logger.warning("firebase_admin not available; returning anonymous user")
        return "anonymous"
    except HTTPException:
        raise
    except Exception as e:
        logger.warning("Token verification failed: %s — using anonymous", e)
        return "anonymous"


def get_analyzer():
    """Return the global GardenAnalyzer instance from app state."""
    from app.main import app_state

    analyzer = app_state.get("model")
    if analyzer is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    return analyzer
