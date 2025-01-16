#Paramters
rg=lab-vnet-encryption
location=centralus

# Deploy Hub and Spoke 
az group create --name $rg --location $location
az deployment group create --name Hub1-$location --resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/azuredeployv6.json \
--parameters https://raw.githubusercontent.com/dmauser/azure-hub-spoke/main/er-hub-transit/parameters.json \
--parameters virtualMachineSize=Standard_DS2_v2 virtualMachinePublicIP=false deployBastion=true \
--no-wait


