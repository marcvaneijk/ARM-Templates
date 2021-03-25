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