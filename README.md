# Kubernetes project — FastAPI in a container

A sample REST API built with **FastAPI**, packaged in **Docker**, deployable on **Kubernetes** (Deployment, LoadBalancer Service, HPA), and delivered via **CI/CD** on GitHub Actions to build and push the image to Docker Hub.

## Stack

| Component | Role |
|-----------|------|
| Python 3.11 | Runtime |
| FastAPI + Uvicorn | HTTP API |
| Docker (Alpine) | Production image |
| Kubernetes | Orchestration, load balancing, scaling |
| GitHub Actions | Image build and push |

## Repository layout

```text
Kubernetes/
├─ app/
│  ├─ __init__.py
│  └─ main.py              # FastAPI app
├─ k8s/
│  ├─ deployment.yaml      # Deployment with probes and resources
│  ├─ service.yaml         # LoadBalancer Service
│  └─ hpa.yaml             # Horizontal Pod Autoscaler (CPU)
├─ .github/
│  └─ workflows/
│     └─ ci-cd.yaml        # CI/CD pipeline
├─ Dockerfile
├─ requirements.txt
├─ .gitignore
└─ README.md
```

## API

| Route | Description |
|-------|-------------|
| `GET /` | Sample JSON response (`mensaje`) |
| `GET /health` | Health check; used by Kubernetes (liveness/readiness) |

The app listens on port **8000** inside the container.

## Local development

1. Create a virtual environment and install dependencies:

   **Windows**

   ```bash
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt
   ```

   **Linux / macOS**

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. Run the API:

   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

3. Try: `http://127.0.0.1:8000/` and `http://127.0.0.1:8000/health`.

## Docker

Build and run the image from the project root:

```bash
docker build -t app-python:local .
docker run -p 8000:8000 app-python:local
```

The `Dockerfile` uses `python:3.11-alpine`, installs `requirements.txt`, copies `app/`, and starts Uvicorn with `app.main:app` on `0.0.0.0:8000`.

## Kubernetes

Manifests under `k8s/`:

- **Deployment** (`api-python-deployment`): replicas, app image, port 8000, **liveness** and **readiness** probes on `/health`, CPU and memory `requests`/`limits`.
- **Service** (`api-python-service`): **LoadBalancer**, port 80 → `targetPort` 8000, selector `app: api-python`. On local setups (minikube, kind, Docker Desktop) the load balancer may behave differently than on a public cloud.
- **HPA** (`api-python-hpa`): scales the deployment between 1 and 5 replicas based on **CPU** usage (average target 50%). Many clusters need **Metrics Server** installed so the HPA can read CPU metrics.

Apply (with `kubectl` configured for your cluster):

```bash
kubectl apply -f k8s/
```

Or apply each file:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

**Deployment image:** the current manifest uses `robpalacios1/app-python:v2`. Align the `image` field with what you publish (CI/CD or local build); the workflow publishes `…/app-python:latest` and `…/app-python:<commit-sha>`.

## CI/CD (GitHub Actions)

File: `.github/workflows/ci-cd.yaml`.

- Runs only on **push** to the **`master`** branch (other branches do not run this workflow).
- Steps: checkout, Docker Hub login, build and push with **docker/build-push-action** (`context: .`, `push: true`).
- Published tags: `<user>/app-python:latest` and `<user>/app-python:<commit-sha>` (the SHA is the commit SHA in GitHub Actions).

**GitHub secrets** (Settings → Secrets and variables → Actions):

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub username (login) |
| `DOCKERHUB_TOKEN` | Docker Hub token or password (login) |
| `DOCKERHUB_USERNAME` | Hub namespace used in the image name in the workflow |

`DOCKER_USERNAME` and `DOCKERHUB_USERNAME` are usually the same Docker Hub ID. The Kubernetes **Deployment** should use the same image repository (`<user>/app-python`) and whichever tag you want to deploy (`latest`, a specific SHA, `v2`, etc.).

## Other files

- **`requirements.txt`:** `fastapi` and `uvicorn` (pinned versions).
- **`.gitignore`:** ignores `venv/`, Python caches, `.idea/`, `.vscode/`, `.env`.

---

## Author

Created by **Roberto Palacios**.  
[LinkedIn profile](https://www.linkedin.com/in/robpalacios1/)