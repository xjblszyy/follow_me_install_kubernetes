#!/bin/bash

# master
# docker pull mirrorgooglecontainers/kube-apiserver:v1.13.0
# docker pull mirrorgooglecontainers/kube-controller-manager:v1.13.0
# docker pull mirrorgooglecontainers/kube-scheduler:v1.13.0
# docker pull mirrorgooglecontainers/kube-proxy:v1.13.0
# docker pull mirrorgooglecontainers/pause:3.1
# docker pull mirrorgooglecontainers/etcd:3.2.24
# docker pull coredns/coredns:1.2.6

# docker tag docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 k8s.gcr.io/kube-proxy:v1.13.0
# docker tag docker.io/mirrorgooglecontainers/kube-scheduler:v1.13.0 k8s.gcr.io/kube-scheduler:v1.13.0
# docker tag docker.io/mirrorgooglecontainers/kube-apiserver:v1.13.0 k8s.gcr.io/kube-apiserver:v1.13.0
# docker tag docker.io/mirrorgooglecontainers/kube-controller-manager:v1.13.0 k8s.gcr.io/kube-controller-manager:v1.13.0
# docker tag docker.io/mirrorgooglecontainers/etcd:3.2.24  k8s.gcr.io/etcd:3.2.24
# docker tag docker.io/mirrorgooglecontainers/pause:3.1  k8s.gcr.io/pause:3.1
# docker tag docker.io/coredns/coredns:1.2.6  k8s.gcr.io/coredns:1.2.6

# docker rmi docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0
# docker rmi docker.io/mirrorgooglecontainers/kube-scheduler:v1.13.0
# docker rmi docker.io/mirrorgooglecontainers/kube-apiserver:v1.13.0
# docker rmi docker.io/mirrorgooglecontainers/kube-controller-manager:v1.13.0
# docker rmi docker.io/mirrorgooglecontainers/etcd:3.2.24
# docker rmi docker.io/mirrorgooglecontainers/pause:3.1
# docker rmi docker.io/coredns/coredns:1.2.6


# slave
docker pull mirrorgooglecontainers/kube-proxy:v1.13.0
docker pull mirrorgooglecontainers/pause:3.1

docker tag docker.io/mirrorgooglecontainers/pause:3.1  k8s.gcr.io/pause:3.1
docker tag docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 k8s.gcr.io/kube-proxy:v1.13.0

docker rmi docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0
docker rmi docker.io/mirrorgooglecontainers/pause:3.1
