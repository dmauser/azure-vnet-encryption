rg=lab-vnet-encryption
# Enable Accelerated Networking in all VM that starts with az-
az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Enabling Accelerated Networking for VM: $vm_name"
    az network nic update --resource-group $rg --name $(az vm show -g $rg -n $vm_name --query "networkProfile.networkInterfaces[0].id" -o tsv | awk -F/ '{print $NF}') --accelerated-networking true -o none
done

### Enabling vNET encryption and set enforcement policy to AllowUnencrypted
# See: https://learn.microsoft.com/en-us/cli/azure/network/vnet?view=azure-cli-latest#az-network-vnet-update
# Loop script to enable vNET encryption in all vnets stat start with az-
az network vnet list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vnet_name; do
    echo "Enabling vNET encryption for vNET: $vnet_name"
    az network vnet update --resource-group $rg --name $vnet_name \
    --enable-encryption true \
    --encryption-enforcement-policy AllowUnencrypted \
    -o none --no-wait
done

# Stop, deallocated and start all VMs in the resource group
az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Stopping VM: $vm_name"
    az vm deallocate --resource-group $rg --name $vm_name -o none
done

az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Starting VM: $vm_name"
    az vm start --resource-group $rg --name $vm_name -o none
done