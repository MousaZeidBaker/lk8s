# Local Kubernetes

All you need for a local Kubernetes setup in one place

## Table of Contents

1. [Kubernetes basics and concepts](#kubernetes-basics-and-concepts)
2. [Prerequisites](#prerequisites)
3. [Getting started](#getting-started)
4. [Build Docker images](#build-docker-images)
5. [Deploy apps](#deploy-apps)
6. [Accessing apps](#accessing-apps)
    1. [Outside the cluster](#outside-the-cluster)
    2. [Within the cluster](#within-the-cluster)
    2. [Access pod B from antoher pod A](#access-pod-b-from-antoher-pod-a)
    2. [Access host resources from a pod](#access-host-resources-from-a-pod)
7. [Logs](#logs)

## Kubernetes basics and concepts

A Kubernetes cluster consists of a set of worker machines, called
[Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/), that run
containerized applications. Containers are placed into
[Pods](https://kubernetes.io/docs/concepts/workloads/pods/) and usually managed
by
[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
A deployment declares the number of replicas of an app that should be running at
a time, it then automatically spins up the requested pods and then monitors
them. If a pod crashes, the deployment will automatically re-create it. A
[Service](https://kubernetes.io/docs/concepts/services-networking/service/)
resource can be used as an abstraction layer to manage network traffic to a set
of pods running an application. Furthermore, an
[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
exposes HTTP and HTTPS routes from outside the cluster to services within the
cluster. Traffic routing is controlled by rules defined on the Ingress resource,
for instance traffic to the URL path `/foo` can be routed to a `foo` service
while traffic to `/bar` can be routed to a `bar` service. 

[![](https://mermaid.ink/img/pako:eNqNkl1vwiAUhv8KwRtNWtdVtxhcvHIXJsti5uXqBS2nSqTQAN1HNv_7qNBok33dwAk873sO5_CBC8UAE7zTtN6jh6d5JhEqBAdph89-347iMVrJnQZj4opKugOG7nK9QEJRhnIqqCxAo3G84J56znDg0fDR-a_WpN3WSttRhrenHAGN48XnVanUpwH9wgu4dtqND9HQnZNZMku-FeVUd6L0UuTO-yLT5P51hWiMBX1h5O9DZudaK9YWsFbslBzRuj7b9LD0Dyz12KTDXFW_YNOfMJDMD4Qas4QS1YJyiUouBBkwxiJjtToAGZRlGeL4lTO7J9P6LSqUUJoMkiSZ90wOMxMsJultATf_cnF3fZfQzeB0lpJBnud9m_Rs4zOenbpJRF17uyCN2mG0yymatMu0Lf1C6_-nb0rv2FcW9jmOcAW6opy5j_7Rchm2e6ggw8SFDEraCJvhTB4d2tSMWrhn3CqNSUmFgQjTxqrNuywwsbqBDlpy6n5WFajjF7P4Hts)](https://mermaid.live/edit#pako:eNqNkl1vwiAUhv8KwRtNWtdVtxhcvHIXJsti5uXqBS2nSqTQAN1HNv_7qNBok33dwAk873sO5_CBC8UAE7zTtN6jh6d5JhEqBAdph89-347iMVrJnQZj4opKugOG7nK9QEJRhnIqqCxAo3G84J56znDg0fDR-a_WpN3WSttRhrenHAGN48XnVanUpwH9wgu4dtqND9HQnZNZMku-FeVUd6L0UuTO-yLT5P51hWiMBX1h5O9DZudaK9YWsFbslBzRuj7b9LD0Dyz12KTDXFW_YNOfMJDMD4Qas4QS1YJyiUouBBkwxiJjtToAGZRlGeL4lTO7J9P6LSqUUJoMkiSZ90wOMxMsJultATf_cnF3fZfQzeB0lpJBnud9m_Rs4zOenbpJRF17uyCN2mG0yymatMu0Lf1C6_-nb0rv2FcW9jmOcAW6opy5j_7Rchm2e6ggw8SFDEraCJvhTB4d2tSMWrhn3CqNSUmFgQjTxqrNuywwsbqBDlpy6n5WFajjF7P4Hts)

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) to setup a local
  Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) to communicate with
  the cluster

## Getting started

Start a local Kubernetes cluster
```shell
minikube start --addons=ingress
```

(Optional) Access the dashboard
```shell
minikube dashboard
```

## Build Docker images

Images are usually built and pushed into a registry and then pulled (downloaded)
by a Kubernetes cluster. But when developing locally one can instead build
directly inside minikube to make images available in the cluster.

Build images located in the `/apps` directory
```shell
for DIR in apps/**; do minikube image build --tag ${DIR##*/} $DIR; done
```

> Note: Each directory inside `/apps` must contain a Dockerfile, the directory
> name is used as the image name and images are tagged with the `latest` tag. To
> list images use `minikube image ls`.

## Deploy apps

Copy `.env.example` to `.env` for each app and configure env variables to your
preferences
```shell
for DIR in kubernetes/**; do cp --no-clobber $DIR/.env.example $DIR/.env; done
```

Apply Kubernetes manifests, to delete resources replace `apply` with `delete`
```shell
for DIR in kubernetes/**; do kubectl apply --kustomize $DIR; done
```

> Note: If an app inside `/apps` is modified make sure to first re-build the
> image inside minikube, then destroy the related deployment resource and lastly
> re-apply it. Otherwise changes won't be detected becuase deployments are (for
> simplicity) configured to use the `latest` tag instead of unique tags.

## Accessing apps

### Outside the cluster

Access apps running in the cluster from outside the cluster by sending requests
to the ingress controller.

Get NodeIP
```shell
NODE_IP=$(minikube ip)
```

> Note: kubectl can also be used:
> ```shell
> kubectl get nodes --output jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
> ```

Get NodePort of the ingress controller
```shell
NODE_PORT=$(kubectl get svc ingress-nginx-controller --namespace ingress-nginx --output jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
```

Hit the `hello` pod
```shell
curl "http://$NODE_IP:$NODE_PORT/hello/v1/echo"
```

### Within the cluster

Some apps are not supposed to be exposed outside the cluster such as a database
or an internal api. In these cases port forwarding can be used to access them.

Get ContainerPort of the `hello` pod
```shell
CONTAINER_PORT=$(kubectl get pods --selector app=hello --output jsonpath='{.items[*].spec.containers[*].ports[*].containerPort}')
```

Forward a LocalPort of your own choice (e.g. `9000`) to a pod's ContainerPort
```shell
kubectl port-forward deployment/hello 9000:$CONTAINER_PORT
```

> Note: kubectl can automatically choose a LocalPort that is not in use if it is
> omitted from the command
> ```shell
> kubectl port-forward deployment/hello :$CONTAINER_PORT
> ```

Hit the `hello` pod
```shell
curl "http://127.0.0.1:9000/v1/echo"
```

### Access pod B from antoher pod A

Get a shell to a running pod A
```shell
kubectl exec --stdin --tty deployment/hello -- /bin/bash
```

Hit pod B
```shell
# when pod B is in the same namespace as pod A
curl <service-name>/v1/echo

# when pod B is NOT in the same namespace as pod A
curl <service-name>.<namespace-name>.svc.cluster.local/v1/echo
```

### Access host resources from a pod

Get a shell to the `hello` pod
```shell
kubectl exec --stdin --tty deployment/hello -- /bin/bash
```

Hit a resource running on host (your machine) on port `8080`
```shell
curl host.minikube.internal:8080/v1/echo
```

> Note: The host must have a running resource. To run the `hello` app use:
> ```shell
> docker-compose --file apps/hello/docker-compose.yml up
> ```

## Logs

```shell
# show snapshot logs from a deployment named hello
kubectl logs deployment/hello

# show snapshot logs in pods defined by label app=hello
kubectl logs --selector app=hello

# show snapshot logs from the ingres-controller pod
POD_NAME=$(kubectl get pods --namespace ingress-nginx --selector app.kubernetes.io/component=controller --output jsonpath='{.items[*].metadata.name}')
kubectl logs $POD_NAME --namespace ingress-nginx

# stream logs
kubectl logs --selector app=hello --follow

# show only the most recent 20 lines of logs
kubectl logs --selector app=hello --tail=20

# show logs written in the last minute
kubectl logs --selector app=hello --since=1m

# for more examples
kubectl logs --help
```
