"""
Configuration — reads from .env file at repo root.
All other modules import from here. Nothing else touches env vars.
"""

import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL: str         = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    raise EnvironmentError(
        "Missing required env vars. Copy .env.example → .env and fill in values."
    )
