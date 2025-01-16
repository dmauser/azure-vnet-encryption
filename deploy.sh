#Paramters
rg=lab-vnet-encryption
location=westcentralus

# Deploy Hub and Spoke 
az group create --name $rg --location $location
az deployment group create --name Hub1-$location --resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/azuredeployv6.json \
--parameters https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/parameters.json \
--parameters virtualMachineSize=Standard_DS2_v2 virtualMachinePublicIP=false deployBastion=true \
--parameters 
--no-wait

# Loop script to check deployment status
while true; do
    status=$(az deployment group show --name Hub1-$location --resource-group $rg --query properties.provisioningState -o tsv)
    echo "Deployment status: $status"
    if [ "$status" == "Succeeded" ]; then
        echo "Deployment succeeded."
        break
    elif [ "$status" == "Failed" ]; then
        echo "Deployment failed."
    fi
    sleep 30 # Wait for 30 seconds before checking again
done
