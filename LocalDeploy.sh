#!/usr/bin/env bash
set -euo pipefail

# ===== НАЛАШТУВАННЯ (міняй під себе) =====
APP_RELEASE="todoapp"
APP_NAMESPACE="todoapp-web-ns"
APP_CHART_PATH="./djangoapp-helm-charts/todoapp-web"
APP_VALUES_FILE="./djangoapp-helm-charts/todoapp-web/values.yaml"  # можна передати інший шлях першим аргументом
APP_SVC_NAME="todoapp-web-service"                           # сервіс апки (із твоїх шаблонів)

PROM_RELEASE="monitoring"
PROM_NAMESPACE="monitoring"
PROM_CHART="prometheus-community/kube-prometheus-stack"
PROM_VALUES_FILE="./djangoapp-helm-charts/values-monitoring.yaml"                     # за потреби можна передати другим аргументом

# Локальні порти
APP_LOCAL_PORT="${APP_LOCAL_PORT:-8080}"
PROM_LOCAL_PORT="${PROM_LOCAL_PORT:-9090}"
GRAFANA_LOCAL_PORT="${GRAFANA_LOCAL_PORT:-3000}"
ALERT_LOCAL_PORT="${ALERT_LOCAL_PORT:-9093}"

# Імена сервісів kube-prometheus-stack (для релізу "monitoring")
PROM_SVC="monitoring-kube-prometheus-prometheus"
GRAFANA_SVC="monitoring-grafana"
ALERT_SVC="monitoring-kube-prometheus-alertmanager"

# ===== ПЕРЕВІРКИ =====
command -v kubectl >/dev/null || { echo "kubectl не знайдено"; exit 1; }
command -v helm >/dev/null || { echo "helm не знайдено"; exit 1; }

# ===== NS =====
kubectl get ns "$APP_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$APP_NAMESPACE"
kubectl get ns "$PROM_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$PROM_NAMESPACE"

# ===== PROM REPO =====
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

echo Please wait until the end of installation it might take some time 🛠️ 😊

# ===== DEPLOY PROMETHEUS STACK =====
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
 -n monitoring -f ./djangoapp-helm-charts/values-monitoring.yaml \
 --atomic --timeout 10m
kubectl get crd servicemonitors.monitoring.coreos.com prometheusrules.monitoring.coreos.com

# ===== DEPLOY APP =====
helm upgrade --install todoapp ./djangoapp-helm-charts/todoapp-web \
  -n todoapp-web-ns -f ./djangoapp-helm-charts/todoapp-web/values.yaml \
  --atomic --timeout 10m


# ===== PORT-FORWARD (з автокілом) =====
pf_pids=()

cleanup() {
  echo ">> Зупиняю port-forward..."
  for pid in "${pf_pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

echo ">> Запускаю port-forward..."
kubectl -n "$APP_NAMESPACE" port-forward svc/"$APP_SVC_NAME" $APP_LOCAL_PORT:80 >/dev/null 2>&1 &
pf_pids+=($!)

kubectl -n "$PROM_NAMESPACE" port-forward svc/"$PROM_SVC" $PROM_LOCAL_PORT:9090 >/dev/null 2>&1 &
pf_pids+=($!)

kubectl -n "$PROM_NAMESPACE" port-forward svc/"$GRAFANA_SVC" $GRAFANA_LOCAL_PORT:80 >/dev/null 2>&1 &
pf_pids+=($!)

kubectl -n "$PROM_NAMESPACE" port-forward svc/"$ALERT_SVC" $ALERT_LOCAL_PORT:9093 >/dev/null 2>&1 &
pf_pids+=($!)

sleep 2
echo "✅ Done:
- App:        http://localhost:$APP_LOCAL_PORT
- Prometheus: http://localhost:$PROM_LOCAL_PORT
- Grafana:    http://localhost:$GRAFANA_LOCAL_PORT  (логіни дивись у секретах релізу $PROM_RELEASE)
- Alertmanager: http://localhost:$ALERT_LOCAL_PORT

Натисни Ctrl+C, щоб зупинити port-forward."
wait
