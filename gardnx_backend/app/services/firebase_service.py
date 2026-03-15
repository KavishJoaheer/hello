"""Firebase Admin SDK operations wrapper."""
import os
import json
from typing import Optional, Any, Dict, List


_firebase_initialized = False


def init_firebase(credentials_path: str, storage_bucket: str) -> bool:
    """Initialize Firebase Admin SDK. Returns True if successful."""
    global _firebase_initialized
    if _firebase_initialized:
        return True

    if not os.path.exists(credentials_path):
        print(f"WARNING: Firebase credentials not found at {credentials_path}. Running without Firebase.")
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred, {'storageBucket': storage_bucket})
        _firebase_initialized = True
        print("Firebase Admin SDK initialized successfully.")
        return True
    except Exception as e:
        print(f"WARNING: Failed to initialize Firebase: {e}")
        return False


def get_firestore():
    """Return Firestore client or None."""
    if not _firebase_initialized:
        return None
    from firebase_admin import firestore
    return firestore.client()


def get_storage_bucket():
    """Return Firebase Storage bucket or None."""
    if not _firebase_initialized:
        return None
    from firebase_admin import storage
    return storage.bucket()


def save_plant_data(plants: List[Dict]) -> int:
    """Seed plants collection in Firestore. Returns count saved."""
    db = get_firestore()
    if not db:
        print("Firestore not available.")
        return 0

    count = 0
    batch = db.batch()
    for plant in plants:
        ref = db.collection("plants").document(plant["id"])
        batch.set(ref, plant)
        count += 1
        if count % 500 == 0:  # Firestore batch limit
            batch.commit()
            batch = db.batch()

    batch.commit()
    return count


def upload_image_to_storage(image_bytes: bytes, path: str) -> Optional[str]:
    """Upload bytes to Firebase Storage, return public URL."""
    bucket = get_storage_bucket()
    if not bucket:
        return None

    blob = bucket.blob(path)
    blob.upload_from_string(image_bytes, content_type="image/jpeg")
    blob.make_public()
    return blob.public_url
