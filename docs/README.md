# WordPress on Kubernetes — Deploy Guide

Prereqs:
- Kubernetes cluster (kubectl configured)
- Helm 3
- Docker daemon and access to push images
- NFS server for RWX volumes (or other RWX CSI driver)

## 1. Build & push Docker images
### from repo root

```
docker build -t nginx-openresty:latest -f docker/nginx/Dockerfile .
docker push nginx-openresty:latest

docker build -t wordpress:latest -f docker/wordpress/Dockerfile .
docker push wordpress:latest

docker build -t mysql:latest -f docker/mysql/Dockerfile .
docker push mysql:latest
```

## 2. Create storage
```
kubectl apply -f k8s/storage/nfs-pv.yaml
kubectl apply -f k8s/storage/wp-content-pvc.yaml
kubectl apply -f k8s/storage/mysql-pvc.yaml
```

## 3. Install monitoring stack (kube-prometheus-stack recommended)

> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

```
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
```

## 4. Deploy helm charts
```
helm install mysql ./charts/mysql
helm install wordpress ./charts/wordpress
helm install nginx ./charts/nginx
```
## 5. Configure ServiceMonitor & PrometheusRule
```
kubectl apply -f k8s/monitoring/servicemonitor-nginx.yaml
kubectl apply -f k8s/monitoring/prometheusrule-wordpress.yaml
```
## 6. Access Grafana
### port-forward if using cluster internal Grafana
``` 
kubectl port-forward svc/prometheus-grafana 3000:80 -n default 
```
> open http://localhost:3000 (default admin/admin; check helm chart for credentials)

## 7. Cleanup
```
helm delete nginx
helm delete wordpress
helm delete mysql
helm delete prometheus
kubectl delete -f k8s/storage/*.yaml

```

```SCSS
[Internet] -> [LoadBalancer / Ingress] -> [nginx (OpenResty + Lua)]
     nginx proxies -> [wordpress (php-fpm) pods]  (mount: wp-content pvc RWX)
     wordpress connects -> [mysql StatefulSet / Pod] (mysql-data pvc RWO)
Monitoring:
  - Prometheus scrapes:
      * kube-state-metrics, node-exporter
      * nginx /metrics (lua exporter)
      * php-fpm /metrics (php-fpm exporter)
      * mysqld_exporter
  - Grafana dashboards visualize metrics
Alerts:
  - High Pod CPU
  - Nginx 5xx spike
  - MySQL high latency / disk usage
```