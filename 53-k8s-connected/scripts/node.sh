#!/bin/bash

# Arguments
UNIQUE_STRING=$1
API_LB_ENDPOINT="$2:6443"
ADMIN_USERNAME=$3
POD_SUBNET="10.244.0.0/16"
KUBEADM_CONF="kubeadm_config.yaml"
# Generate a 32 byte key from the unique string
CERTIFICATE_KEY=$(echo $UNIQUE_STRING | xxd -p -c 32 -l 32)
# Generate the bootstrap token from the unique string
# [a-z0-9]{6}\.[a-z0-9]{16}
BOOTSTRAP_TOKEN="${UNIQUE_STRING:0:6}"."${UNIQUE_STRING:6:16}"

echo "===== ARGS ===="
echo ${UNIQUE_STRING}
echo ${API_LB_ENDPOINT}
echo ${POD_SUBNET}
echo ${OVERLAY_CONF}
echo ${KUBEADM_CONF}
echo ${CERTIFICATE_KEY}
echo ${BOOTSTRAP_TOKEN}

# Installation
echo "===== update package database ====="
sudo apt-get update \
  && echo "## Pass: updated package database" \
  || { echo "## Fail: failed to update package database" ; exit 1 ; }

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


echo "===== Join node to the cluster ====="

cat <<EOF >${KUBEADM_CONF}
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: "${API_LB_ENDPOINT}"
    token: "${BOOTSTRAP_TOKEN}"
    unsafeSkipCAVerification: true
  timeout: 5m0s
EOF

sudo kubeadm join --config ${KUBEADM_CONF} \
  && echo "## Pass: Join control plane node to Kubenetes cluster" \
  || { echo "## Fail: failed to join control plane node to Kubernetes cluster" ; exit 1 ; }



echo "===== Copy conf files to user context ====="

#mkdir -p /home/$ADMIN_USERNAME/.kube \
#  && echo "## Pass: Create .kube folder in home dir" \
#  || { echo "## Fail: failed to create .kube folder in home dir" ; exit 1 ; }

#sudo cp -T -v /etc/kubernetes/admin.conf /home/$ADMIN_USERNAME/.kube/config \
#  && echo "## Pass: Copy admin.conf to .kube" \
#  || { echo "## Fail: failed to copy admin.conf to .kube" ; exit 1 ; }

#sudo chown $(id -u $ADMIN_USERNAME):$(id -g $ADMIN_USERNAME) /home/$ADMIN_USERNAME/.kube/config \
#  && echo "## Pass: Set permissions on .kube/config folder" \
#  || { echo "## Fail: failed to set permissions on .kube/config folder" ; exit 1 ; }