# Lab: Azure Virtual Network Encryption

## Intro

This a lab to demonstrate how to enable encryption for Azure Virtual Network and validate it using Traffic Analytics.
Below are the links to the official documentation to help you understand the concepts and the steps to enable encryption for Azure Virtual Network.

- [What is Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-overview)
- [Frequently asked questions for Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-faq)
- [Create a virtual network with encryption](https://learn.microsoft.com/en-us/azure/virtual-network/how-to-create-encryption)

## Important takeaways

-Please review the official documentation to confirm which VM sizes support vNET encryption. For this lab, we will use the Standard_D2d_v4 size to maintain minimal costs.
- Using the vNET encryption feature incurs no charges, apart from the costs associated with supported VM sizes. Enabling Accelerated Networking comes at no additional cost.
- Ensure that Accelerated Networking is enabled for all VMs.
- Once vNET encryption is activated, it functions transparently and will not impact VMs that do not support it.
At this time, the only way to validate whether vNET encryption is operational is to utilize vNET Flow Logs. Integrating these logs with Traffic Analytics is crucial for effectively visualizing the data.

## Lab Scenario

This lab builds a Hub and Spoke in Azure and emulates vNET for the On-premises. Both are connected using S2S IPSec VPN using VPN Virtual Network Gateways.

Here are the steps to deploy the lab and make the appropriate configurations to enable vNET encryption and validations:

### Step 1 - Run the base lab deployment script

On this step, provide the username and password.

```bash
curl -sL https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/1-deploy.sh | bash
```

### Step 2 - Validation before enabling vNET encryption

Run the following commands to generate traffic.

```bash
# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done
```

### Step 3 - Enabling vNET encryption

Note that you can review the steps executed by the script by clicking on the link below.

```bash
curl -sL https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/2-enable-vnet-encryption.sh | bash
```

This script ensures all VMs on the Azure side are enabled to use Accelerated Networking.

### Step 4 - Validation after enabling vNET encryption



### Accessing VMs using Bastion

To access the VMs, you can use the Azure Bastion service. The script below will provide you with the necessary information to access the VMs.

```bash	
###### BASTION SSH ######
# Open a new terminal for each VM
# Note: change the rg variable to the resource group name you used in the deployment
# az-hub-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-hub-lxvm --query id -o tsv) --auth-type password --username $username
# az-spk1-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk1-lxvm --query id -o tsv) --auth-type password --username $username
# az-spk1-lxvm2
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk1-lxvm2 --query id -o tsv) --auth-type password --username $username
# az-spk2-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk2-lxvm --query id -o tsv) --auth-type password --username $username
# onprem-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name onprem-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n onprem-lxvm --query id -o tsv) --auth-type password --username $username
```
