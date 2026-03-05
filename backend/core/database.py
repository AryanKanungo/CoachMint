"""
Supabase client — single instance shared across the app.
Import get_db() wherever a DB connection is needed.
"""

from supabase import create_client, Client
from core.config import SUPABASE_URL, SUPABASE_SERVICE_KEY

_client: Client | None = None


def get_db() -> Client:
    global _client
    if _client is None:
        _client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    return _client
