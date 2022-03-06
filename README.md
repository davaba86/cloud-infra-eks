# EKS with Remote Access

## TLDR

The purpose of this repo is to give you a very basic setup in order to start experimenting with EKS and to get some experience with HELM.

You'll also be using AWS with DNS directly as a local setup on your laptop won't really prepare you for the work needed around topics like DNS.

## Prerequisites

This assumes you've:

- got basic knowlege in AWS services and how to use Terraform.
- got your own Route53 domain and know how to manage it, for eg. transfer control of a Google domain to Route53.
- installed AWS CLI, Terraform, eksctl and kubectl.
- created an AWS IAM user and are able able to authenticate by for eg. running `aws s3 ls` and not receiving any error messages.

## Setup

1. Deploy cluster with eksctl, and this can take around 15 min depending on your setup.

   ```bash
   eksctl create cluster -f eksctl-selfmanaged-node-grp.yml
   ```

2. Once eksctl is done, verify your cluster is up by contacting the API server.

   ```bash
   kubectl get nodes
   NAME                                           STATUS   ROLES    AGE   VERSION
   ip-192-168-81-235.eu-west-1.compute.internal   Ready    <none>   8h    v1.21.5-eks-9017834
   ```

3. Edit line 222 in `ingress-nginx-nginxinc.yml` with your own public IP address.
4. Apply ingress Nginx config.

   ```bash
   kubectl apply -f ingress-nginx-nginxinc.yml
   ```

5. Edit lines 12, 22, 32, 42 and 52 in `ingress-apps.yml` with your own domain.
6. Edit line 119 with your own PostgreSQL default password in `ingress-apps.yml`.
7. Edit line 5 with your own PostgreSQL default password in `helm-db1-exporter.yml`.
8. Apply applications.

   ```bash
   kubectl apply -f ingress-apps.yml
   ```

9. Extract the AWS LB DNS.

   ```bash
   kubectl get svc -n nginx-ingress
   ```

10. Edit line 3 with the AWS LB DNS in `ingress-apps.tf`.
11. Edit line 8 with your own domain `ingress-apps.tf`.
12. Edit line 13 with your own domain Router53 zone ID `ingress-apps.tf`.
13. Apply the changes to AWS via Terraform.

    ```bash
    terraform apply -auto-approve
    ```

14. Install DB exporter containers through HELM.

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install db1 prometheus-community/prometheus-postgres-exporter -f helm-db-exporter.yml
    helm install db2 prometheus-community/prometheus-mongodb-exporter -f helm-db2-exporter.yml
    ```

## Verification

1. Check ingress and ensure that host row (except web1) has one backend IP and port listed like below.

   ```bash
   ❯ kubectl describe ingress
   Name:             micro-ingress
   Namespace:        default
   Address:
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host                              Path  Backends
     ----                              ----  --------
     web1.changeme.com
                                       /   web1:80 (192.168.91.156:80,192.168.91.37:80)
     metrics.changeme.com
                                       /   metrics-kube-prometheus-st-prometheus:9090 (192.168.81.52:9090)
     dashboard.changeme.com
                                       /   metrics-grafana:80 (192.168.66.79:3000)
     db1-exporter.changeme.com
                                       /   db1-prometheus-postgres-exporter:80 (192.168.89.143:9187)
     db2-exporter.changeme.com
                                       /   db2-prometheus-mongodb-exporter:9216 (192.168.89.80:9216)
   Annotations:                        kubernetes.io/ingress.class: nginx
                                       nginx.org/rewrites: serviceName=apache-svc rewrite=/
   Events:
     Type    Reason          Age                   From                      Message
     ----    ------          ----                  ----                      -------
     Normal  AddedOrUpdated  17m (x66 over 7h11m)  nginx-ingress-controller  Configuration for default/micro-ingress was added or updated
   ```

2. Open your metrics URL, for eg. metrics.changeme.com and login with admin/promp-operator.
3. Change the admin password.
4. Verify web1 via your web browser, for eg. <http://web1.changeme.com>.
5. Verify db1 metrics via your web browser, for eg. <http://db1-exporter.changeme.com/metrics>.
6. Verify db2 metrics via your web browser, for eg. <http://db2-exporter.changeme.com/metrics>.

## Cleanup

Always cleanup your AWS env when you're not working with it.

```bash
eksctl delete cluster basic-cluster
```
