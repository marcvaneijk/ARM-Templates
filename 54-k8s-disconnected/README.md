# Deploy Kubernetes on a disconnected Azure Stack environment

Before you can deploy Kubernetes on a disconnected Azure Stack environment, ensure you have performed the prerequisite steps described [here](/deploy/initialize/README.md).

### Deploy the solution
Login to the Azure Stack tenant portal with a user that has access contributor access on the subscription that contains the newly created managed image. Select to create a new resource and search for **template deployment** in the marketplace. Select **edit template** and copy the [disconnected - deployment template](https://github.com/marcvaneijk/kubernetes/blob/master/deploy/disconnected/azuredeploy.json) to template editor and hit save.

The deployment template requires the following inputs:

- managedDiskResourceId: Specify the id for the managed disk created from the source VHD. The script in the previous provided the id in the output. You can also retrieve the information from the portal, by going to the properties of the managed disk and select the resource id.

- adminUsername : The username of your vm. The default value is vmadmin.
- sshPublicKey : The public key of your SSH keypair
- prefix: The name of the resources in Azure Stack will be based of this prefix. You can use the fedault value or specify you own.
- artifactsLocation: The default value requires internet connectivity. Since you are deploying to an Azure Stack environment that is disconnected you will have to provide you own value. Use the Uri to the storage container that you used to upload your deployment artifact to, described in the [prerequisites](/deploy/initialize/README.md). The Uri must end with a trailing forward slash (/). For example https://mystorageaccount.region.azuretack.local/artifactscontainer/
- managedImageName: The name of the managed image you created in the [prerequisites](/deploy/initialize/README.md)
- managedImageResourceGroup: The resource group name containing the managed image created in the the [prerequisites](/deploy/initialize/README.md)

The deployment takes about 30 minutes and by default creates 3 masters and 3 nodes joined to the cluster. The public IP address is connected to a load balancer. The load balancer is configured with a inbound rule for 6443 (the default kubernetes API port) and 3 inbound NAT rules for the 3 masters.

- kube-master1: ssh vmadmin@publicip -p 22001
- kube-master2: ssh vmadmin@publicip -p 22002
- kube-master3: ssh vmadmin@publicip -p 22003

### Known issues
If you are unable to SSH into a master because of a certificate mismatch (although you are sure you used the correct public key during the deployment), you'll have to reset you ssh key. You can do this in the portal, by opening the blade for the VM and select "reset password" in the Support + troubleshooting section on the left of the blade. Select "Reset SSH public key+ and submit the same username (vmadmin) and ssh public key used during the deployment. Select update. Once the task is complete you should be able to connect with your SSH client.