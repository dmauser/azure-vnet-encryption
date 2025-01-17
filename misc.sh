# Loop script to resize all vms that contains az- to Standard_D2d_v4
az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Resizing VM: $vm_name"
    az vm resize --resource-group $rg --name $vm_name --size Standard_D2d_v4 -o none
done

#### Bastion SSH using ADD ####
# Enable ADD login integration
rg=lab-vnet-encryption

# Add ADD SSH Login for Linux extension to all vms in the resource group
az vm list -g $rg --query "[].name" -o tsv | while read vm_name; do
    echo "Adding ADD extension to VM: $vm_name"
    az vm extension set \
        --publisher Microsoft.Azure.ActiveDirectory \
        --name AADSSHLoginForLinux \
        --resource-group $rg \
        --vm-name $vm_name \
        --no-wait \
        -o none
done

# Enable system assigned managed identity on all VMs in the resource group
az vm list -g $rg --query "[].name" -o tsv | while read vm_name; do
    echo "Enabling system assigned managed identity on VM: $vm_name"
    az vm identity assign --resource-group $rg --name $vm_name -o none --no-wait
done

# Bastion SSH VMs in the resource group
# az-hub-lxvm 
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-hub-lxvm --query id -o tsv) --auth-type aad
# az-spk1-lxvm 
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk1-lxvm --query id -o tsv) --auth-type aad
# az-spk1-lxvm2 
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk1-lxvm2 --query id -o tsv) --auth-type aad
# az-spk2-lxvm 
az network bastion ssh --name az-hub-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n az-spk2-lxvm --query id -o tsv) --auth-type aad
# onprem-lxvm
az network bastion ssh --name onprem-bastion --resource-group $rg --target-resource-id $(az vm show -g $rg -n onprem-lxvm --query id -o tsv) --auth-type aad