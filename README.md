# Kubernetes — FastAPI API in a container and EKS (AWS)

A sample **FastAPI** REST API packaged as a **Docker** image, with **Kubernetes** manifests (Deployment, LoadBalancer Service, HPA) and **Terraform** infrastructure for an **Amazon EKS** cluster. The image is built and published to Docker Hub via **GitHub Actions**.

## Stack

| Component | Role |
|-----------|------|
| Python 3.11 | Runtime |
| FastAPI + Uvicorn | HTTP API |
| Docker (Alpine) | Production image |
| Kubernetes (EKS) | Orchestration, load balancing, scaling |
| Terraform + AWS | VPC, EKS, and node group |
| GitHub Actions | Image build and push |

## Repository layout

```text
Kubernetes/
├─ app/
│  ├─ __init__.py
│  └─ main.py                 # FastAPI app
├─ k8s/
│  ├─ deployment.yaml         # Deployment, probes, resources
│  ├─ service.yaml            # LoadBalancer Service
│  └─ hpa.yaml                # CPU-based HPA
├─ terraform/
│  ├─ main.tf                 # AWS provider (us-east-1)
│  ├─ vpc.tf                  # VPC, public subnets, IGW, routes
│  ├─ eks.tf                  # EKS cluster
│  ├─ nodes.tf                # Node group (EC2)
│  └─ iam.tf                  # IAM roles for cluster and nodes
├─ .github/
│  └─ workflows/
│     └─ ci-cd.yaml           # CI/CD pipeline
├─ Dockerfile
├─ requirements.txt
├─ .gitignore
└─ README.md
```

## API

| Route | Description |
|-------|-------------|
| `GET /` | Sample JSON response (`mensaje`) |
| `GET /health` | Health check; used by Kubernetes liveness/readiness probes |

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

From the project root:

```bash
docker build -t app-python:local .
docker run -p 8000:8000 app-python:local
```

The `Dockerfile` uses `python:3.11-alpine`, installs `requirements.txt`, copies `app/`, and starts Uvicorn with `app.main:app` on `0.0.0.0:8000`.

## Infrastructure (Terraform on AWS)

The `terraform/` directory defines:

- **Region:** `us-east-1` (provider in `main.tf`).
- **Network:** VPC `10.0.0.0/16`, two public subnets (`10.0.1.0/24`, `10.0.2.0/24`) in `us-east-1a` and `us-east-1b`, Internet Gateway, and a route table to `0.0.0.0/0`.
- **EKS:** cluster `api-python-cluster` in those subnets.
- **Nodes:** group `api-python-node-node-group`, `t3.micro` instances, desired scaling 2 (min 1, max 3).
- **IAM:** roles and attached policies for the EKS control plane and for nodes (worker, CNI, ECR read-only).

Prerequisites: [Terraform](https://www.terraform.io/), [AWS CLI](https://aws.amazon.com/cli/) configured with credentials and permissions to create VPC, EKS, EC2, and IAM resources.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After deployment, configure `kubectl` for the cluster (adjust region and name if you change them):

```bash
aws eks update-kubeconfig --region us-east-1 --name api-python-cluster
```

**Note:** `terraform.tfstate` files often contain sensitive data; check `.gitignore` and avoid committing state to public repositories carelessly.

## Kubernetes

Manifests under `k8s/`:

- **Deployment** (`api-python-deployment`): replicas, image, port 8000, **liveness** and **readiness** probes on `/health`, CPU and memory `requests`/`limits`.
- **Service** (`api-python-service`): **LoadBalancer**, port 80 → `targetPort` 8000, selector `app: api-python`. On EKS the cloud provider provisions the load balancer; behavior may differ on local setups.
- **HPA** (`api-python-hpa`): scales between 1 and 5 replicas based on **CPU** at 50% average utilization. **Metrics Server** is usually required in the cluster for CPU metrics used by the HPA.

Apply (with `kubectl` pointed at your cluster):

```bash
kubectl apply -f k8s/
```

Or apply each file:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

**Deployment image:** the manifest uses `robpalacios1/app-python:v2`. Align the `image` with what you publish (CI/CD or local build). The GitHub workflow publishes `<user>/app-python:latest` and `<user>/app-python:<commit-sha>`.

## CI/CD (GitHub Actions)

File: `.github/workflows/ci-cd.yaml`.

- Runs on **push** to the **`master`** branch (other branches do not trigger this workflow).
- Steps: checkout, Docker Hub login, build and push with **docker/build-push-action** (`context: .`, `push: true`).
- Published tags: `<user>/app-python:latest` and `<user>/app-python:<github.sha>`.

**GitHub secrets** (Settings → Secrets and variables → Actions):

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub username (login and image namespace) |
| `DOCKERHUB_TOKEN` | Docker Hub token or password for login |

The Kubernetes **Deployment** should use the same image repository (`<user>/app-python`) and whichever tag you deploy (`latest`, a specific SHA, `v2`, etc.).

## Other files

- **`requirements.txt`:** `fastapi` and `uvicorn` (pinned versions).
- **`.gitignore`:** excludes `venv/`, Python caches, `.idea/`, `.vscode/`, `.env`, and Terraform state where applicable.

---

## Author

Created by **Roberto Palacios**.  
[LinkedIn profile](https://www.linkedin.com/in/robpalacios1/)
