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

### Check at the OS Level if the Accelerated Networking is enabled. That can be done in any VM on the hub and spoke networks
# Example:
sudo lspci
# Expected output with Accelerated Networking enabled:
# fcbc:00:02.0 Ethernet controller: Mellanox Technologies MT27800 Family [ConnectX-5 Virtual Function] (rev 80)
# Only Azure VMs has Accelerated Networking enabled, on-premises VMs does not have this feature.

# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done


# Check Network Watchet Traffic Analytics (it may take up to 15 minutes to start collecting data):

# IntraVNET
# Traffic between az-spk1-lxvm (10.0.1.4) and az-spk1-lxvm2 (10.0.1.5)
//IntraVNET
NTANetAnalytics
| where SrcIp contains "10.0.1.4" and DestIp contains "10.0.1.5"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType

# InterVNET
# Traffic between az-hub-lxvm (10.0.0.4) and az-spk1-lxvm (10.0.1.4)
//InterVNET
NTANetAnalytics
| where SrcIp contains "10.0.0.4" and DestIp contains "10.0.1.4"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType

# On-premises to Azure
# Traffic between onprem-lxvm (192.168.100.4) and az-spk1-lxvm (10.0.1.4)
NTANetAnalytics
//On-premises
| where SrcIp contains "192.168.100.4" and DestIp contains "10.0.1.4"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType
