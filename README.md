# Local deployment of Django App + DB + monitoring (Helm/K8s/Prometheus) and CI on GitHub Actions.
This repository contains the infrastructure for deploying and testing Django App in Kubernetes. It uses a Helm chart for the web service with a sub-chart for the database, monitoring based on kube-prometheus-stack (Prometheus/Grafana/Alertmanager), local scripts for quick start (Bootstrap + deploy), and simple CI in GitHub Actions (lint/chart render, kube‑linter, e2e‑smoke in kind with image preload). The goal is a reproducible local experience and a direct path to the cloud through values overlays (dev/ci/staging/prod).

## Requirements

- `kubectl` ≥ 1.28
- `Helm` ≥ 3.14
- Minikube (for local) or any compatible K8s cluster
- Docker (for building/loading images)


## Quick start (locally)

1) Cluster and add-ons

```bash
chmod +x Bootstrap.sh
./Bootstrap.sh
```

2) Deploy the application and monitoring

```bash
chmod +x script.sh
./script.sh
```

The script does the following:

- creates the todoapp-web-ns and monitoring namespaces;
- sets up kube-prometheus-stack (CRD for ServiceMonitor/PrometheusRule);
- sets up the application chart;

- Runs port forwarding:
  - App → http://localhost:8080
  - Prometheus → http://localhost:9090
  - Grafana → http://localhost:3000
  - Alertmanager → http://localhost:9093


## CI (GitHub Actions)

1) Helm Validate

- Helm dependency update, helm lint.
- Helm template (base + CI overlay).
- Path filters only trigger on chart/overlays/scripts changes
- Сoncurrency cancels in-progress runs for the same branch/PR

2) e2e-kind

- Creates a kind cluster.
- Preloads the docker image into the kind node.
- Installs the chart from overlays/ci/values-ci.yaml (persistence=false, hpa=false, serviceMonitor=false, rules=false).
- Waits for the Deployment to be Ready, then performs a /api/health smoke check


## Clean up

1) Soft delete (remove releases and NS)
```bash
helm uninstall todoapp -n todoapp-web-ns || true
helm uninstall monitoring -n monitoring || true
kubectl delete ns todoapp-web-ns monitoring || true
```

2) Hard (remove Minikube profile)
```bash
minikube delete -p todoapp
```









