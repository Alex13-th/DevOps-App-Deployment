# DevOps-App-Deployment



helm install todoapp ./djangoapp-helm-charts/todoapp-web   -n todoapp-web-ns   --create-namespace   --dry-run   --debug




# якщо образ у GHCR (приватний):
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=alex13-th \
  --docker-password=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 \
  -n todoapp-web-ns




minikube addons enable ingress
minikube addons enable metrics-server



CHART=./djangoapp-helm-charts/todoapp-web
REL=todoapp
NS=todoapp-web-ns

helm install "$REL" "$CHART" -n "$NS" --create-namespace --dry-run --debug



# real instal

helm install todoapp ./djangoapp-helm-charts/todoapp-web -n todoapp-web-ns --create-namespace


validate

kubectl get pods -n todoapp-web-ns
kubectl get pods -n db-ns
kubectl get pvc -n todoapp-web-ns
kubectl get ingress -n todoapp-web-ns