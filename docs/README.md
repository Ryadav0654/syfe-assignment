

# 🚀 WordPress + OpenResty (NGINX + Lua) + MySQL on Kubernetes

**Helm + Docker + Prometheus/Grafana Monitoring**

This project deploys a full WordPress stack on Kubernetes using custom Docker images and Helm charts.
It includes:

* **OpenResty / NGINX** with:

  * Lua integration
  * `lua-resty-prometheus` metrics
  * `/metrics` endpoint for Prometheus
  * Proxy pass → WordPress backend
* **WordPress** running behind the NGINX reverse proxy
* **MySQL** as the WordPress database
* **Prometheus + Grafana** for metrics & dashboards
* **Persistent storage (PV/PVC)**
* **Automated deploy script (`deploy.sh`)**
* **Automated cleanup (`destroy.sh`)**

---

## 📦 Components

### 1. Docker Images

Custom Dockerfiles in `docker/` directory:

| Component       | Path                | Description                                                                                                    |
| --------------- | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| NGINX/OpenResty | `docker/nginx/`     | Compiles OpenResty with Lua, installs `lua-resty-prometheus`, loads custom `nginx.conf` and Lua metrics logic. |
| WordPress       | `docker/wordpress/` | Custom WordPress image.                                                                                        |
| MySQL           | `docker/mysql/`     | Optional initialization scripts + local dev–friendly MySQL image.                                              |

Builds are automatically handled by `deploy.sh`.

---

### 2. Helm Charts

Each service has its own Helm chart:

```
charts/
 ├── nginx/
 ├── wordpress/
 └── mysql/
```

Each chart includes:

* Deployment
* Service
* ConfigMap
* Secret (for MySQL credentials)
* PV/PVC references
* NGINX proxy logic (nginx chart)
* Lua metrics integration

You can install any component individually or as a full stack.

---

### 3. Monitoring

Monitoring is deployed via:

```
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack
```

Includes:

* Prometheus
* Grafana
* Node Exporter
* Kube State Metrics

ServiceMonitors for NGINX metrics are in:

```
k8s/monitoring/
```

---

### 4. Storage

Storage manifests live under:

```
k8s/storage/
```

Includes:

* PV for MySQL data
* PV for WordPress wp-content
* PVCs bound to deployments

Kubernetes will dynamically bind the volumes.

---

## 🚀 Deployment

### 1. Make the script executable

```bash
chmod +x deploy.sh
```

### 2. Deploy the entire stack

```bash
./deploy.sh <tag> <namespace>
```

Example:

```bash
./deploy.sh v1 wordpress
```

If you omit args:

* `tag = latest`
* `namespace = wordpress`

This script:

1. Builds Docker images
2. Applies PV/PVC storage
3. Installs Prometheus + Grafana
4. Deploys MySQL
5. Deploys WordPress
6. Deploys NGINX OpenResty
7. Applies monitoring ServiceMonitors

---

## 🗑️ Cleanup

Run:

```bash
./destroy.sh <namespace>
```

Example:

```bash
./destroy.sh wordpress
```

This removes:

* All Helm releases (nginx, wordpress, mysql, prometheus)
* All PV/PVC for that namespace
* Namespace itself

---

## 🌐 Access the Applications

### WordPress

Get service info:

```bash
kubectl get svc wordpress -n <namespace>
```

### NGINX Reverse Proxy

```bash
kubectl get svc nginx -n <namespace>
```

### Grafana

Forward Grafana to localhost:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n <namespace>
```

Open:

**[http://localhost:3000](http://localhost:3000)**

Default credentials:

```
username: admin
password: prom-operator
```

---

## 🔍 Verifying the Deployment

Check pods:

```bash
kubectl get pods -n <namespace>
```

Check logs:

```bash
kubectl logs deployment/nginx -n <namespace>
kubectl logs deployment/wordpress -n <namespace>
kubectl logs deployment/mysql -n <namespace>
```

Check PV/PVC:

```bash
kubectl get pv,pvc -n <namespace>
```

Check metrics:

```bash
kubectl exec -it deployment/nginx -n <namespace> -- curl localhost/metrics
```

---

## 🛠️ Local Development (Docker Desktop)

If using Docker Desktop Kubernetes:

* Kubernetes must be enabled
* All images are built locally so **no registry** is required
* Helm installs services into your chosen namespace

---

## 📁 Repository Structure

```
.
├── charts/
│   ├── mysql/
│   ├── nginx/
│   └── wordpress/
├── docker/
│   ├── mysql/
│   ├── nginx/
│   └── wordpress/
├── k8s/
│   ├── monitoring/
│   └── storage/
├── deploy.sh
├── destroy.sh
├── README.md
└── .gitignore
```


