#!/usr/bin/env bash
set -euo pipefail

minikube start
minikube addons enable metrics-server >/dev/null
minikube addons enable ingress >/dev/null
echo "$(minikube ip) todoapp.local" | sudo tee -a /etc/hosts


echo "Minikube IP: $(minikube ip)"
