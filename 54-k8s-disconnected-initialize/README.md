# Initialize the VHD on Azure and download it

## Create source VHD on Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmarcvaneijk%2Fkubernetes%2Fmaster%2Fdeploy%2Finitialize%2Fazuredploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

You can either click the "deploy to Azure button" or sign in to the Azure Portal, select to create a new resource and search for **template deployment** in the marketplace. In the template deployment marketplace item, select to **build your own template** in the editor and copy the [initialize - deployment template](https://raw.githubusercontent.com/marcvaneijk/kubernetes/master/deploy/initialize/azuredeploy.json) to template editor and hit save.

The deployment template will create an Ubuntu VM, installs packages, installs docker and pulls the required container images (Kubernetes, Calico) and deployment scripts.
You will need to specify the following parameters

- adminUsername: The username of your vm. The default value is vmadmin.
- sshPublicKey: The public key of your SSH keypair
- artifactsLocation: This default value can be used. If you want to create a fork of this repository to make changes to the scripts, you can override the artifactsLoaction with you own value, to use your own scripts.

## Deprovision the waagent
Once the deployment is complete you will have to deprovision the Azure VM agent to delete machine-specific files and data. 

- Connect to your Linux VM with an SSH client.
- In the SSH window, enter the following commands:

  ``` bash
  sudo waagent -deprovision+user -force
  export HISTSIZE=0
  exit
  ```

- Shutdown the VM from the portal. Since the waagent is deprovisioned this can take a couple of minutes.

## Download the VHD from Azure
Once the shutdown is completed, [download the VHD from Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/download-vhd) from a local machine with internet connectivity. The initialize deployment template is configured with an unmanaged disk that contains the vhd, allowing for easy retrieval (e.g. using [storage explorer](https://azure.microsoft.com/en-us/features/storage-explorer/))

## Download the deployment templates from GitHub
The kubenetes deployment templates are stored on this repository in GitHub and are not accesibel from an Azure Stack in a disconnected environment. You will need to donwload these artifacts (the main deployment template and the linked templates) from a client with internet connectivity. You can use the following PowerShell script or clone the repo with git.

``` PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Variables
$Uri = "https://raw.githubusercontent.com/marcvaneijk/kubernetes/master/deploy/disconnected/"
$LocalPath = 'c:\k8sdisconnected\'
$files= @("azuredeploy.json","linked/network.json","linked/master.json","linked/node.json","linked/masterconfig.json","linked/nodeconfig.json")

# Create folder
New-Item "$LocalPath\linked" -type directory -Force

# Download files
$files | ForEach-Object {
    Invoke-WebRequest ($Uri + $_) -OutFile (Join-Path -Path $LocalPath -ChildPath $_)
}
```

# Prepare the disconnected Azure Stack environment

## Upload the VHD to Azure Stack
Sign into Azure Stack and create a storage account. Within storage account create a blob container. Upload the VHD into the container (e.g. select upload file from the container in the portal)

## Create a managed image from a VHD in a storage account

Create a managed image from the VHD that you just uploaded to the storage account. You need the URI of the VHD in the storage account, which is in the following format: https://mystorageaccount.region.azuretack.local/vhdcontainer/vhdfilename.vhd. In this example, the VHD is in mystorageaccount, in a container named vhdcontainer, and the VHD filename is vhdfilename.vhd.


Open a PowerShell session and [connect to Azure Stack with PowerShell as a user](https://docs.microsoft.com/en-us/azure-stack/user/azure-stack-powershell-configure-user)

Once singed in to Azure Stack, create a managed disk from the VHD that you uploaded earlier

``` PowerShell
$rgName = "myResourceGroup"
$location = "region"
$imageName = "kubernetes"
$osVhdUri = "https://mystorageaccount.region.azuretack.local/vhdcontainer/vhdfilename.vhd"

$imageConfig = New-AzureRmImageConfig -Location $location
$imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Linux -OsState Generalized -BlobUri $osVhdUri
$image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $rgName -Image $imageConfig
```

> Remember the ```resource group name``` and the ```imagename``` as you will need these values as input for the deployment of Kubernetes.

## Upload template artifacts
The deployment templates you downloaded earlier (if you followed this guide they are stored in c:\k8disconnected), will have to make them available to Azure Stack. The easiest way to do this is to create a storage account on Azure Stack and set the access policy of the container to "Blob (anonymous read access for blobs only)". Upload the files from c:\k8disconnected to the blob. You can do that through the portal. Make sure file and folder sctructure is the same as in your local folder (the linked templates are stored in a folder called "linked" within the blob).

- container
    - azudeploy.json
    - linked
        - network.json
        - master.json
        - node.json
        - masterconfig.json
        - nodeconfig.json

> Remember the ```Url to the container``` as you will need these values as input for the deployment of Kubernetes.

You are now ready to start the deployment, read the install steps [here](/deploy/disconnected/README.md)
