# EKS with Remote Access

## TLDR

The purpose of this repo is to give you a very basic setup in order to start experimenting with EKS and to get some experience with HELM.

You'll also be using AWS with DNS directly as a local setup on your laptop won't really prepare you for the work needed around topics like DNS.

## Prerequisites

This assumes you've:

- got basic knowlege in AWS services and how to use Terraform.
- got your own Route53 domain and know how to manage it, for eg. transfer control of a Google domain to Route53.
- installed AWS CLI, Terraform, eksctl, kubectl and sed/gsqd (if macOS).
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

3. Update the following files before provisioning the env.

   ```bash
   # Use your own Public IP to secure your lab env
   gsed -i "s|my_public_ip/cidr|9.9.9.9/32|g" ingress-nginx-values.yml

   # Use your own and managed domain
   gsed -i "s|my_domain|myowndomain.com|g" ingress-apps.yml
   gsed -i "s|my_domain|myowndomain.com|g" ingress-apps.tf

   # Use your own Route53 DNS Zone ID
   gsed -i "s|my_dns_zone_id|7W34Y5FB34757348G5G63|g" ingress-apps.tf

   # Use your own custom DB password
   gsed -i "s|my_db_password|DwYqiE9fDAAWmZu6j9/Cxn7S/4N+mgprUw==|g" ingress-apps.yml
   gsed -i "s|my_db_password|DwYqiE9fDAAWmZu6j9/Cxn7S/4N+mgprUw==|g" helm-db1-exporter.yml
   ```

4. Provision your kubernetes env.

   ```bash
   # Install Ingress Nginx Controller from Kubernetes organisation
   helm upgrade --repo https://kubernetes.github.io/ingress-nginx \
      --values ingress-nginx-values.yaml \
      --namespace ingress-nginx \
      --create-namespace \
      --install ingress-nginx ingress-nginx

   # Provision k8s apps
   kubectl apply -f ingress-apps.yml
   ```

5. Extract the AWS LB DNS.

   ```bash
   kubectl get svc -n nginx-ingress
   ```

6. Use your AWS LB DNS address.

   ```bash
   gsed -i "s|aws_lb_dns|changeme.elb.amazonaws.com|g" ingress-apps.yml
   ```

7. Apply the changes to AWS via Terraform.

   ```bash
   terraform apply -auto-approve
   ```

8. Install DB exporter containers through HELM.

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install db1 prometheus-community/prometheus-postgres-exporter -f helm-db1-exporter.yml
   helm install db2 prometheus-community/prometheus-mongodb-exporter -f helm-db2-exporter.yml
   helm install metrics prometheus-community/kube-prometheus-stack --version "33.2.0"
   ```

## Verification

> Please be aware that it may take a few minutes (1-5) before the DNS records start working properly, even if all resources are up.

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
