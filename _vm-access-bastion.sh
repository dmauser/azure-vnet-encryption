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