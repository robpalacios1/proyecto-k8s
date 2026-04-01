from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"mensaje": "¡Test from the container!"}

@app.get("/health")
def health_check():
    # Kubernetes will use this route to know if the app is alive
    return {"status": "ok"}