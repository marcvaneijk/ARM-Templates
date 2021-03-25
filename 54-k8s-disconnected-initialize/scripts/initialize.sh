#!/bin/bash

# Arguments
ADMIN_USERNAME=$1
ARTIFACTS_LOCATION=$2
OVERLAY_CONF="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

# Installation
echo "===== update package database ====="
sudo apt-get update \
  && echo "## Pass: updated package database" \
  || { echo "## Fail: failed to update package database" ; exit 1 ; }

## Needed for flannel?
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
/sbin/sysctl -p /etc/sysctl.conf

echo "===== install prereq packages ====="
sudo apt-get install -y apt-transport-https curl \
  && echo "## Pass: prereq packages installed" \
  || { echo "## Fail: failed to install prereq packages" ; exit 1 ; }

echo "===== install Docker ====="
sudo apt-get install -y docker.io \
  && echo "## Pass: installed docker" \
  || { echo "## Fail: failed to install docker" ; exit 1 ; }

echo "===== add gpg key for Google ====="
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - \
  && echo "## Pass: added GPG key for Google repository" \
  || { echo "## Fail: failed to add GPG key for Google repository" ; exit 1 ; }

echo "===== add Kubernetes repository ====="
cat << EOF | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "===== update package database ====="
sudo apt-get update \
  && echo "## Pass: updated package database" \
  || { echo "## Fail: failed to update package database" ; exit 1 ; }

echo "===== install Kubernetes components ====="
sudo apt-get install -y kubelet kubeadm kubectl \
  && echo "## Pass: Install Kubernetes components" \
  || { echo "## Fail: failed to install Kubernetes components" ; exit 1 ; }

# Fix warning 1
sudo systemctl enable docker.service \
  && echo "## Pass: Apply fix for kubeadm init warning" \
  || { echo "## Fail: failed to apply fix for kubeadm init warning" ; exit 1 ; }

# Fix warning 2
cat << EOF | sudo tee -a /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d \
  && echo "## Pass: Apply fix for kubeadm init warning" \
  || { echo "## Fail: failed to apply fix for kubeadm init warning" ; exit 1 ; }

sudo systemctl daemon-reload \
  && echo "## Pass: reload daemon" \
  || { echo "## Fail: failed to reload daemon" ; exit 1 ; }

sudo systemctl restart docker \
  && echo "## Pass: restart docker" \
  || { echo "## Fail: failed to restart docker" ; exit 1 ; }

# Pull Kubernetes images
sudo kubeadm config images pull \
  && echo "## Pass: download Kubernetes images" \
  || { echo "## Fail: failed to download Kubernetes images" ; exit 1 ; }

# Download flannel config file
sudo mkdir /kube \
  && echo "## Pass: create kube folder in root" \
  || { echo "## Fail: failed to create kube folder in root" ; exit 1 ; }

sudo curl $OVERLAY_CONF -o /kube/flannel.yaml \
  && echo "## Pass: download Flannel config file" \
  || { echo "## Fail: failed to download Flannel config file" ; exit 1 ; }

# Pull flannel images
sudo docker pull quay.io/coreos/flannel:v0.11.0-amd64 \
  && echo "## Pass: pull image quay.io/coreos/flannel:v0.11.0-amd64" \
  || { echo "## Fail: failed to pull image quay.io/coreos/flannel:v0.11.0-amd64" ; exit 1 ; }

sudo curl $2scripts/controlPlane.sh -o /kube/controlPlane.sh \
  && echo "## Pass: download controlPlane.sh script" \
  || { echo "## Fail: failed to download controlPlane.sh script" ; exit 1 ; }

sudo curl $2scripts/node.sh -o /kube/node.sh \
  && echo "## Pass: download controlPlane.sh script" \
  || { echo "## Fail: failed to download controlPlane.sh script" ; exit 1 ; }
