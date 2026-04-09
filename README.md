# Kubernetes — FastAPI API in a container and EKS (AWS)

A sample **FastAPI** REST API packaged as a **Docker** image, with **Kubernetes** manifests (Deployment, LoadBalancer Service, HPA), **Prometheus-compatible metrics**, and **Terraform** infrastructure for an **Amazon EKS** cluster. The image is built and published to Docker Hub via **GitHub Actions**.

## Stack

| Component | Role |
|-----------|------|
| Python 3.11 | Runtime |
| FastAPI + Uvicorn | HTTP API |
| prometheus-fastapi-instrumentator | Prometheus metrics on `/metrics` |
| Docker (Alpine) | Production image |
| Kubernetes (EKS) | Orchestration, load balancing, scaling |
| Terraform + AWS | VPC, EKS, IAM, and managed node group |
| GitHub Actions | Image build and push |

## Repository layout

```text
Kubernetes/
├─ app/
│  ├─ __init__.py
│  └─ main.py                 # FastAPI app, Prometheus instrumentation
├─ k8s/
│  ├─ deployment.yaml         # Deployment, probes, resources, image tag
│  ├─ service.yaml            # LoadBalancer + Prometheus scrape annotations
│  └─ hpa.yaml                # CPU-based HPA (autoscaling/v2)
├─ terraform/
│  ├─ main.tf                 # AWS provider (us-east-1)
│  ├─ vpc.tf                  # VPC, public subnets, IGW, routes, ELB tags
│  ├─ eks.tf                  # EKS cluster
│  ├─ nodes.tf                # Managed node group (EC2)
│  └─ iam.tf                  # IAM roles for cluster and nodes
├─ .github/
│  └─ workflows/
│     └─ ci-cd.yaml           # CI/CD: build and push on master
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
| `GET /metrics` | Prometheus metrics (exposed by prometheus-fastapi-instrumentator) |

The app listens on port **8000** inside the container.

## Observability (Prometheus)

The app uses **[prometheus-fastapi-instrumentator](https://github.com/trallnag/prometheus-fastapi-instrumentator)** to expose standard HTTP metrics on **`/metrics`**.

The **Service** (`k8s/service.yaml`) includes annotations so Prometheus (or compatible scrapers) can discover targets:

- `prometheus.io/scrape: "true"`
- `prometheus.io/port: "8000"` (container port where metrics are served)
- `prometheus.io/path: "/metrics"`

Ensure your Prometheus instance can reach the pods or Service (network policies, scrape config, or ServiceMonitor if you use the Prometheus Operator). After deploying, you can verify metrics locally with port-forwarding, for example:

```bash
kubectl port-forward svc/api-python-service 8000:80
curl http://127.0.0.1:8000/metrics
```

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

3. Try: `http://127.0.0.1:8000/`, `http://127.0.0.1:8000/health`, and `http://127.0.0.1:8000/metrics`.

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
- **Network:** VPC `10.0.0.0/16` (`api-python-vpc`), DNS support/hostnames enabled for EKS; two public subnets (`10.0.1.0/24` in `us-east-1a`, `10.0.2.0/24` in `us-east-1b`) with `kubernetes.io/role/elb` tags; Internet Gateway; public route table to `0.0.0.0/0`; route table associations for both subnets.
- **EKS:** cluster `api-python-cluster` using those subnet IDs.
- **Nodes:** managed group `api-python-node-node-group`, **`t3.micro`** instances, scaling desired **2** (min **1**, max **3**).
- **IAM:** `api-python-eks_cluster_role` with `AmazonEKSClusterPolicy`; `api-python-eks-node-role` with worker, CNI, and ECR read-only policies for nodes.

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

**Note:** Terraform state files can contain sensitive data; `.gitignore` excludes `.terraform/`, `*.tfstate`, and related files—avoid committing state to public repositories carelessly.

## Kubernetes

Manifests under `k8s/`:

- **Deployment** (`api-python-deployment`): replicas, container image, port **8000**, **liveness** and **readiness** probes on `/health`, CPU and memory **requests**/**limits**.
- **Service** (`api-python-service`): **LoadBalancer**, port **80** → **targetPort** **8000**, selector `app: api-python`, plus **Prometheus scrape annotations** (see Observability). On EKS the cloud controller provisions the load balancer; behavior differs on local clusters (e.g. minikube).
- **HPA** (`api-python-hpa`, `autoscaling/v2`): **1–5** replicas based on **CPU** at **50%** average utilization. **Metrics Server** is required in the cluster for CPU metrics used by the HPA.

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

**Deployment image:** the manifest pins a specific image such as `robpalacios1/app-python:<git-commit-sha>`. After each CI run, update the Deployment `image` to match the tag you want (`latest`, a specific `github.sha`, etc.). The GitHub workflow publishes `<user>/app-python:latest` and `<user>/app-python:<commit-sha>`.

## CI/CD (GitHub Actions)

File: `.github/workflows/ci-cd.yaml`.

- Runs on **push** to the **`master`** branch only.
- Steps: checkout, Docker Hub login, build and push with **docker/build-push-action** (`context: .`, `push: true`).
- Published tags: `<user>/app-python:latest` and `<user>/app-python:<github.sha>`.

**GitHub secrets** (Settings → Secrets and variables → Actions):

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub username (login and image namespace) |
| `DOCKERHUB_TOKEN` | Docker Hub token or password for login |

The Kubernetes **Deployment** should use the same image repository (`<user>/app-python`) and the tag you deploy (`latest`, a specific SHA, etc.).

## Other files

- **`requirements.txt`:** `fastapi`, `uvicorn`, and `prometheus-fastapi-instrumentator` (versions pinned where applicable).
- **`.gitignore`:** excludes `venv/`, Python caches, `.idea/`, `.vscode/`, `.env`, and Terraform state and `.terraform` artifacts.

---

## Author

Created by **Roberto Palacios**.  
[LinkedIn profile](https://www.linkedin.com/in/robpalacios1/)
