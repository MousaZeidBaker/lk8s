# lk8s

All you need for a local Kubernetes setup in one place

## Table of Contents

1. [Kubernetes basics and concepts](#kubernetes-basics-and-concepts)
2. [Prerequisites](#prerequisites)
3. [Getting started](#getting-started)
    1. [Build Docker images](#build-docker-images)
    2. [Deploy apps](#deploy-apps)
    4. [Port forwarding](#port-forwarding)
    6. [Access pod B from another pod A](#access-pod-b-from-another-pod-a)
    7. [Access host resources from a pod](#access-host-resources-from-a-pod)
7. [Logs](#logs)

## Kubernetes basics and concepts

A Kubernetes cluster consists of a set of worker machines, called
[Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/), that run
containerized applications. Containers are placed into
[Pods](https://kubernetes.io/docs/concepts/workloads/pods/) and usually managed
by
[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
A deployment declares the number of replicas of an app that should be running at
a time, it then automatically spins up the requested pods and monitors them. If
a pod crashes, the deployment will automatically re-create it. A
[Service](https://kubernetes.io/docs/concepts/services-networking/service/)
resource can be used as an abstraction layer to manage network traffic to a set
of pods. Furthermore, an
[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
exposes HTTP and HTTPS routes from outside the cluster to services within the
cluster. Traffic routing is controlled by rules defined on the Ingress resource,
for instance traffic to the URL path `/foo` can be routed to a `foo` service
while traffic to `/bar` can be routed to a `bar` service.

[![](https://mermaid.ink/img/pako:eNqNkl1vwiAUhv8KwRtNWueqWwwuXrkLk2Ux83L1gpZTJVJogO4j6n8fFRptsq8bODk873vgHA44VwwwwVtNqx16epmlEqFccJC2_-r3zSAeoqXcajAmLqmkW2DoIdNzJBRlKKOCyhw0GsZz7qnXFAce9Z-d_3JFmm2ltB2keHOuEdA4nh9vCqWOBvQbz-HWadc-RH2XJ9PRt5KM6laSXEtc_lpi6sy_LBe1saCvbPx5qOo8K8Wa4ivFzoURraqLTQdL_sASj41bzN3pF2zyEwaS-WFQYxZQoEpQLlHBhSA9xlhkrFZ7IL2iKEIcv3Nmd2RSfUS5EkqT3mg0mnVM9lMTLMbJfQ53_3JxZ12X0M3gdJGSXpZlXZvkYuMrXpzaSURte9sgiZphNMs5GjfLpLn6ldb_Td-UTtrfLOwzHOESdEk5c5_80HAptjsoIcXEhQwKWgub4lSeHFpXjFp4ZNwqjUlBhYEI09qq9afMMbG6hhZacOp-Vhmo0xedox4L)](https://mermaid.live/edit#pako:eNqNkl1vwiAUhv8KwRtNWueqWwwuXrkLk2Ux83L1gpZTJVJogO4j6n8fFRptsq8bODk873vgHA44VwwwwVtNqx16epmlEqFccJC2_-r3zSAeoqXcajAmLqmkW2DoIdNzJBRlKKOCyhw0GsZz7qnXFAce9Z-d_3JFmm2ltB2keHOuEdA4nh9vCqWOBvQbz-HWadc-RH2XJ9PRt5KM6laSXEtc_lpi6sy_LBe1saCvbPx5qOo8K8Wa4ivFzoURraqLTQdL_sASj41bzN3pF2zyEwaS-WFQYxZQoEpQLlHBhSA9xlhkrFZ7IL2iKEIcv3Nmd2RSfUS5EkqT3mg0mnVM9lMTLMbJfQ53_3JxZ12X0M3gdJGSXpZlXZvkYuMrXpzaSURte9sgiZphNMs5GjfLpLn6ldb_Td-UTtrfLOwzHOESdEk5c5_80HAptjsoIcXEhQwKWgub4lSeHFpXjFp4ZNwqjUlBhYEI09qq9afMMbG6hhZacOp-Vhmo0xedox4L)

## Prerequisites

- [docker](https://docs.docker.com/get-docker/)
- [k3d](https://k3d.io/) to setup a local Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) to communicate with
  the cluster
- port `8080` and `8443` must not be in use

## Getting started

Following guide shows how to setup a local Kubernetes cluster and how to deploy
a [hello](./apps/hello/) container mainteined locally and a
[whoami](https://hub.docker.com/r/traefik/whoami) container maintained by 3rd
parties that can be pulled from public container registries. Addiotionally, the
[ingress-nginx](https://kubernetes.github.io/ingress-nginx/) controller and the
[Kubernetes
Dasboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
will be deployed.

Start a local Kubernetes cluster 
```shell
k3d cluster create --config k3d-config.yaml
```

### Build Docker images

Images are usually built and pushed into a registry and then pulled (downloaded)
by a Kubernetes cluster. But when developing locally one can instead use a local
registry. K3d has already created one, view it with `docker ps --filter
name=registry`.

Build images located in the `/apps` directory
```shell
for DIR in apps/**; do docker build --tag ${DIR##*/} --tag localhost:5000/${DIR##*/} $DIR; done
```

> Note: Each directory inside `/apps` must contain a Dockerfile, the directory
> name is used as the image name and images are tagged with the `latest` tag.

Push images to the local registry
```shell
for DIR in apps/**; do docker push localhost:5000/${DIR##*/}; done
```

> Note: To list images in the local registry use `curl
> "http://localhost:5000/v2/_catalog"`

### Deploy apps

Copy `.env.example` to `.env` for each deployment and configure env variables as
needed
```shell
for DIR in kubernetes/*/; do cp --no-clobber $DIR/.env.example $DIR/.env; done
```

Apply Kubernetes manifests. To delete resources replace `apply` with `delete`.
```shell
kubectl apply --kustomize kubernetes
```

That's it! You've successfully completed the setup.

Hit `hello` pod over HTTP
```shell
curl "http://hello.127.0.0.1.nip.io:8080/v1/echo"
```

Hit `hello` pod over HTTPS
```shell
curl --insecure "https://hello.127.0.0.1.nip.io:8443/v1/echo"
```

Hit `whoami` pod over HTTP
```shell
curl "http://whoami.127.0.0.1.nip.io:8080"
```

Access Kubernetes Dashboard at
[`http://kubernetes.127.0.0.1.nip.io:8080/dashboard/`](http://kubernetes.127.0.0.1.nip.io:8080/dashboard/)

> Note: If an app inside `/apps` is modified make sure to first re-build the
> image, then re-push it to the local registry, then destroy the related
> deployment resource and lastly re-apply it. Otherwise changes won't be detected
> because deployments are (for simplicity) configured to use the `latest` tag
> instead of unique tags.

#### Port forwarding

Some apps are not supposed to be exposed outside the cluster such as a database
or an internal api. In these cases port forwarding can be used to access them.

Get ContainerPort for the `hello` pod
```shell
CONTAINER_PORT=$(kubectl get pods --selector app=hello --output jsonpath='{.items[*].spec.containers[*].ports[*].containerPort}')
```

Forward a LocalPort of your own choice (e.g. `9000`) to a pod's ContainerPort
```shell
kubectl port-forward deployment/hello 9000:$CONTAINER_PORT
```

Hit the `hello` pod
```shell
curl "http://localhost:9000/v1/echo"
```

#### Access pod B from another pod A

Get a shell to the `hello` pod
```shell
kubectl exec --stdin --tty deployment/hello -- /bin/bash
```

Hit `whoami` pod
```shell
# when pod B is in the same namespace as pod A
# curl "http://<service-name>/some/path"
curl "http://whoami/"

# when pod B is NOT in the same namespace as pod A
# curl "<service-name>.<namespace-name>.svc.cluster.local/some/path"
curl "http://whoami.default.svc.cluster.local/"
```

#### Access host resources from a pod

Get a shell to the `hello` pod
```shell
kubectl exec --stdin --tty deployment/hello -- /bin/bash
```

Hit a resource running on host (your machine) on port `9000`
```shell
curl "host.k3d.internal:9000/"
```

> Note: The host must have a running resource. Run `whoami` with `docker run -p
> 9000:9000 traefik/whoami --port 9000`

### Logs

```shell
# show snapshot logs from a deployment named hello
kubectl logs deployment/helloGet a shell to the `hello` pod

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