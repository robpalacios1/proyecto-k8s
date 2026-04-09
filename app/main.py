from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

#recolect metrics and expose them on /metrics
instrumentator = Instrumentator().instrument(app).expose(app)

@app.get("/")
def read_root():
    return {"mensaje": "¡Test from the container!"}

@app.get("/health")
def health_check():
    # Kubernetes will use this route to know if the app is alive
    return {"status": "ok"}