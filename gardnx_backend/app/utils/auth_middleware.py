"""Firebase authentication middleware."""
from fastapi import HTTPException, Header
from typing import Optional


async def verify_firebase_token(authorization: Optional[str] = Header(None)) -> str:
    """Verify Firebase ID token from Authorization header, return uid."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = authorization.split("Bearer ", 1)[1].strip()

    try:
        import firebase_admin.auth as firebase_auth
        decoded = firebase_auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {str(e)}")
