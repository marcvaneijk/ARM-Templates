#!/bin/bash

# Arguments
NODE_INDEX=$1
UNIQUE_STRING=$2
API_LB_ENDPOINT="$3:6443"
ADMIN_USERNAME=$4
POD_SUBNET="10.244.0.0/16"
OVERLAY_CONF="/kube/flannel.yaml"
KUBEADM_CONF="kubeadm_config.yaml"
# Generate a 32 byte key from the unique string
CERTIFICATE_KEY=$(echo $UNIQUE_STRING | xxd -p -c 32 -l 32)
# Generate the bootstrap token from the unique string
# [a-z0-9]{6}\.[a-z0-9]{16}
BOOTSTRAP_TOKEN="${UNIQUE_STRING:0:6}"."${UNIQUE_STRING:6:16}"

if [ "$NODE_INDEX" = "1" ]; then

  echo "===== Creating the cluster on the first node ====="

cat <<EOF >${KUBEADM_CONF}
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: "${BOOTSTRAP_TOKEN}"
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
certificateKey: "${CERTIFICATE_KEY}"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: "${POD_SUBNET}"
kubernetesVersion: "stable"
controlPlaneEndpoint: "${API_LB_ENDPOINT}"
EOF

  sudo kubeadm init --config ${KUBEADM_CONF} --upload-certs \
    && echo "## Pass: Initiale Kubenetes cluster" \
    || { echo "## Fail: failed to initialize Kubernetes cluster" ; exit 1 ; }

  # Apply network overlay
  sudo kubectl apply -f ${OVERLAY_CONF} --kubeconfig /etc/kubernetes/admin.conf \
    && echo "## Pass: Applied network overlay" \
    || { echo "## Fail: failed to apply network overlay" ; exit 1 ; }

else

  echo "===== Adding an additional control plane node to the cluster ====="

cat <<EOF >${KUBEADM_CONF}
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
controlPlane:
  certificateKey: "${CERTIFICATE_KEY}"
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

fi

echo "===== Copy conf files to user context ====="

mkdir -p /home/$ADMIN_USERNAME/.kube \
  && echo "## Pass: Create .kube folder in home dir" \
  || { echo "## Fail: failed to create .kube folder in home dir" ; exit 1 ; }

sudo cp -T -v /etc/kubernetes/admin.conf /home/$ADMIN_USERNAME/.kube/config \
  && echo "## Pass: Copy admin.conf to .kube" \
  || { echo "## Fail: failed to copy admin.conf to .kube" ; exit 1 ; }

sudo chown $(id -u $ADMIN_USERNAME):$(id -g $ADMIN_USERNAME) /home/$ADMIN_USERNAME/.kube/config \
  && echo "## Pass: Set permissions on .kube/config folder" \
  || { echo "## Fail: failed to set permissions on .kube/config folder" ; exit 1 ; }