# Lab: Azure Virtual Network Encryption

## Intro

This a lab to demonstrate how to enable encryption for Azure Virtual Network and validate it using Traffic Analytics.
Below are the links to the official documentation to help you understand the concepts and the steps to enable encryption for Azure Virtual Network.

- [What is Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-overview)
- [Frequently asked questions for Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-faq)
- [Create a virtual network with encryption](https://learn.microsoft.com/en-us/azure/virtual-network/how-to-create-encryption)

## Important takeaways

- At the time of this article's writing, there are compatibility limitations interacting with other Azure products such as Azure DNS and Private Link Service. Please review the [limitations](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-overview#limitations) section on the official documentation.
- Please review the official documentation to confirm which VM sizes support vNET encryption.
    - We will use the Standard_D2d_v4 size for this lab to maintain minimal costs.
- Using the vNET encryption feature incurs no charges, apart from the costs associated with supported VM sizes.
- All VMs must have Accelerated Networking enabled. Also, enabling Accelerated Networking comes at no additional cost.
- The official documentation shows minimal performance overheads when using vNET encryption, but these are generally negligible. The feature is designed to be transparent and should not significantly impact the performance of your VMs.
    - The main reason is that the encryption processing is offloaded to a specialized hardware called FPGA (Field-Programmable Gate Array). 
    - More information about FPGA: [Azure Accelerated Networking: SmartNICs in the Public Cloud](https://www.microsoft.com/en-us/research/uploads/prod/2018/03/Azure_SmartNIC_NSDI_2018.pdf?msockid=14a99a3dc95567bc03778f53c8f4664c) and [Inside the Microsoft FPGA-based configurable cloud](https://www.microsoft.com/en-us/research/video/inside-microsoft-fpga-based-configurable-cloud/?msockid=14a99a3dc95567bc03778f53c8f4664c)
- At this time, the only way to validate whether vNET encryption is operational is to utilize vNET Flow Logs. Integrating these logs with Traffic Analytics is crucial for effectively visualizing the data. That is demonstrated in the lab below.

## How vNET encryption works

Based on the links shared on the previous section, here is a summary of how vNET encryption works:

### Intra-vNET

![](./media/how-encryption-works-intra.png)

### Inter-vNET

![](./media/how-encryption-works-inter.png)

## Lab diagram

![Lab Diagram](./media/diagram.gif)

### Traffic Flows

Below you can find the traffic flows for this lab:

![Traffic Flows](./media/traffic-flows.png)

## Lab Scenario

This lab builds a Hub and Spoke in Azure and emulates vNET for the On-premises. Both are connected using S2S IPSec VPN using VPN Virtual Network Gateways.

To deploy the lab, you can close this GitHub Repositor and use VS code or run the commands below via [Cloud Shell](https://shell.azure.com) to deploy the lab.

Here are the steps to deploy the lab and make the appropriate configurations to enable vNET encryption and validations:

### Step 1 - Run the base lab deployment script

In this step, provide the username and password.

```bash
wget -q -O 1-deploy.sh https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/1-deploy.sh
chmod +x 1-deploy.sh
./1-deploy.sh
```

### Step 2 - Validation before enabling vNET encryption

#### 2.1 - Generating traffic before enabling vNET encryption

Note: To access each VM, use Serial Console or Bastion [instructions](#accessing-vms-using-bastion) below.

```bash
# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On az-spk2-lxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done
```

#### 2.2 - Review Traffic Analytics for encryption validation.

Access Network Watcher - Log Analytics, select FlowFlog Type: VNet, and click "Launch Log Search Query".

Note: it should take 15-20 minutes to show data after deploying the lab.

![](./media/traffic-analytics.png)

Run the following query:

```Kusto
NTANetAnalytics
| where TimeGenerated > ago(1h) 
// Show all SSH traffic, use the filters below to narrow down
//| where SrcIp contains "10.0.1.5" //ssh traffic from az-spk1-lxvm2
//| where SrcIp contains "10.0.1.4" //ssh traffic from az-spk1-lxvm
//| where SrcIp contains "10.0.2.4" //ssh traffic from az-spk2-lxvm
//| where SrcIp contains "192.168.100.4" //ssh traffic from onprem-lxvm
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| where DestPort == 22
| where FlowType !contains "Unknown" //Remove noise
| project
    TimeGenerated,SrcIp,DestIp,DestPort,FlowEncryption,FlowType,FlowDirection,FlowStatus
| sort by TimeGenerated desc
```

Expected output:

![](./media/logs-kusto.png)

### Step 3 - Enabling vNET encryption

```bash
curl -sL https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/3-enable-vnetencryption.sh | bash
```

Here are the steps included in the [script](./3-enable-vnetencryption.sh) to enable vNET encryption:
1) Enable Accelerated Networking for all VMs (except for the on-premises VM).
2) Enable vNET encryption in all Azure vNET (az-hub-vnet, az-spk1-vnet, az-spk2-vnet).
3) Stop, deallocate, and start all VMs (except for the on-premises VM). That is required to activate the vNET encryption feature of the target VMs.


### Step 4 - Validation after enabling vNET encryption

#### 4.1 - Checking Accelerated Networking

On any of the Azure VMs, run the following command to validate that Accelerated Networking is enabled:

```bash
sudo lspci
# Expected output with Accelerated Networking enabled:
fcbc:00:02.0 Ethernet controller: Mellanox Technologies MT27800 Family [ConnectX-5 Virtual Function] (rev 80)
# Only Azure VMs have Accelerated Networking enabled, on-premises VMs does not have this feature.
# The expected output for VMs without Accelerated Networking is an empty output.
```

On the Azure Portal, you can also make the same validate the Azure VM NIC, as shown:

![](./media/nic-accelnet.png)


#### 4.2 - Checking vNET encryption via Azure Portal

After you run the script on step 3, you can also review the Virtual Network properties and see if VNET encryption is enabled, as shown below:

![](./media/vnet-encryption.png)

#### 4.3 - Generating traffic after enabling vNET encryption

Note: To access each VM, use Serial Console or Bastion [instructions](#accessing-vms-using-bastion) below.

```bash
# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On az-spk2-lxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done
```

#### 4.4 - Reviewing Traffic Analytics for encryption validation

```Kusto
NTANetAnalytics
| where TimeGenerated > ago(1h) 
// Show all SSH traffic, use the filters below to narrow down
//| where SrcIp contains "10.0.1.5" //ssh traffic from az-spk1-lxvm2
//| where SrcIp contains "10.0.1.4" //ssh traffic from az-spk1-lxvm
//| where SrcIp contains "10.0.2.4" //ssh traffic from az-spk2-lxvm
//| where SrcIp contains "192.168.100.4" //ssh traffic from onprem-lxvm
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| where DestPort == 22
| where FlowType !contains "Unknown" //Remove noise
| project
    TimeGenerated,SrcIp,DestIp,DestPort,FlowEncryption,FlowType,FlowDirection,FlowStatus
| sort by TimeGenerated desc
```

Expected output:
![](./media/traffic-analytics-enc.png)

## Accessing VMs using Bastion

To access the VMs, you can use the Azure Bastion service. The script below will provide you with the necessary information to access the VMs.

```bash	
###### BASTION SSH ######
# Open a new terminal for each VM
# Note: change the rg variable to the resource group name you used in the deployment
# az-hub-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg \
--target-resource-id $(az vm show -g $rg -n az-hub-lxvm --query id -o tsv) \
--auth-type password \
--username $username

# az-spk1-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg \
--target-resource-id $(az vm show -g $rg -n az-spk1-lxvm --query id -o tsv) \
--auth-type password \
--username $username

# az-spk1-lxvm2
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg \
--target-resource-id $(az vm show -g $rg -n az-spk1-lxvm2 --query id -o tsv) \
--auth-type password \
--username $username

# az-spk2-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name az-hub-bastion --resource-group $rg \
--target-resource-id $(az vm show -g $rg -n az-spk2-lxvm --query id -o tsv) \
--auth-type password \
--username $username

# onprem-lxvm
rg=lab-vnet-encryption
username=azureuser
az network bastion ssh --name onprem-bastion --resource-group $rg \
--target-resource-id $(az vm show -g $rg -n onprem-lxvm --query id -o tsv) \
--auth-type password \
--username $username
```

## Lab Cleanup
To remove all resources created by this lab, run the following command:

```bash
# Note: change the rg variable to the resource group name you used in the deployment
rg=lab-vnet-encryption
az group delete -n $rg -y --no-wait
```

### Conclusion

On this lab you learned how to enable encryption for Azure Virtual Network and validate it using Traffic Analytics.
