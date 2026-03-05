from fastapi import FastAPI
from routers.engine import router as engine_router

app = FastAPI(title="CoachMint API", version="1.0.0")
app.include_router(engine_router)


@app.get("/health")
def health():
    return {"status": "ok"}
