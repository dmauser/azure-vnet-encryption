#Paramters
rg=lab-vnet-encryption
vmsize=Standard_D2d_v4 # This is a VM size supported by VNET encryption

# Prompt for location
read -p "Enter the location (hit enter for default: westus3): " location
location=${location:-westus3} # Prompt for location, default to westus3 if not provided

# Prompt for username and password 
# Set region unsername and password
read -p "Enter your username (hit enter for default: azureuser): " username
username=${username:-azureuser} # Prompt for username, default to azureuser if not provided
while true; do
  read -s -p "Enter your password: " password
  echo
  read -s -p "Confirm your password: " password_confirm
  echo
  [ "$password" = "$password_confirm" ] && break
  echo "Passwords do not match. Please try again."
done

# Adding script starting time and finish time
start=`date +%s`
echo "Script started at $(date)"

# Check lab-vnet-encryption resource group if exist prompt to delete
echo Checking if $rg resource group exists...
if [ $(az group exists --name $rg) = true ]; then
    read -p "Resource group $rg already exists. Do you want to delete it? (y/n): " delete_rg
    if [ "$delete_rg" == "y" ]; then
        echo "Deleting resource group $rg..."
        az group delete --name $rg --yes
    else
        echo "Exiting script..."
        exit 1
    fi
fi

# Deploy Hub and Spoke 
echo Deploying Hub and Spoke...
az group create --name $rg --location $location -o none
az deployment group create --name Hub1-$location --resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/azuredeployv6.json \
--parameters https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/parameters.json \
--parameters virtualMachineSize=$vmsize virtualMachinePublicIP=false deployBastion=true \
--parameters VmAdminUsername=$username VmAdminPassword=$password \
--no-wait

# If the command above shows an error, stop script
if [ $? -ne 0 ]; then
    echo "Error deploying Hub and Spoke. Exiting script..."
    exit 1
fi

# Loop script to check deployment status
while true; do
    status=$(az deployment group show --name Hub1-$location --resource-group $rg --query properties.provisioningState -o tsv)
    echo "Deployment status: $status"
    if [ "$status" == "Succeeded" ]; then
        echo "Deployment succeeded."
        break
    elif [ "$status" == "Failed" ]; then
        echo "Deployment failed."
        exit 1
    fi
    sleep 30 # Wait for 30 seconds before checking again
done

# Create a VM2 in the spokevnet no public IP:
echo Creating vm az-spk1-lxvm2...
az vm create --resource-group $rg --name az-spk1-lxvm2 --image Ubuntu2204 --public-ip-address "" --size $vmsize  --vnet-name az-spk1-vnet --subnet subnet1 --admin-username $username --admin-password $password --nsg "" --no-wait --only-show-errors

# Only continue if all VMs in the resource group are running and in succeeded state
echo Checking if all VMs are running...
az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Waiting for VM: $vm_name to be in 'VM running' state."
    while true; do
        vm_status=$(az vm get-instance-view --resource-group $rg --name $vm_name --query "instanceView.statuses[?code=='PowerState/running']" -o tsv)
        if [ -n "$vm_status" ]; then
            echo "VM: $vm_name is running."
            break
        else
            echo "VM: $vm_name is not running yet. Checking again in 30 seconds."
            sleep 30
        fi
    done
done

# Turning az-hub-lxvm into a router
echo Turning az-hub-lxvm into a router...
### Enable IP Forwarded on the az-hub-lxvm nic
az network nic update --resource-group $rg --name az-hub-lxvm-nic --ip-forwarding true -o none --no-wait
### az run command on az-hub-lxvm using uri: https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh
az vm run-command invoke -g $rg -n az-hub-lxvm --command-id RunShellScript --scripts "curl -s https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh | bash" -o none --no-wait

# Create UDRs and associate to subnets
echo Creating UDRs and associate them to the subnets...
# Get private ip froom az-hub-lxvm network interface
hub_private_ip=$(az network nic show --resource-group $rg --name az-hub-lxvm-nic --query "ipConfigurations[0].privateIPAddress" -o tsv)
# Create a route table named spoke-to-hub
az network route-table create --name az-rt-spoke-to-hub --resource-group $rg --location $location --disable-bgp-route-propagation true -o none
# Add a route to the route table
az network route-table route create --name 10prefix  --resource-group $rg --route-table-name az-rt-spoke-to-hub --address-prefix 10.0.0.0/8 --next-hop-type VirtualAppliance --next-hop-ip-address $hub_private_ip -o none
az network route-table route create --name 172prefix --resource-group $rg --route-table-name az-rt-spoke-to-hub --address-prefix 172.16.0.0/12 --next-hop-type VirtualAppliance --next-hop-ip-address $hub_private_ip -o none
az network route-table route create --name 192prefix --resource-group $rg --route-table-name az-rt-spoke-to-hub --address-prefix 192.168.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address $hub_private_ip -o none
# Associate route table to subnet1 on az-spk1-vnet and az-spk2-vnet
az network vnet subnet update --resource-group $rg --vnet-name az-spk1-vnet --name subnet1 --route-table az-rt-spoke-to-hub -o none
az network vnet subnet update --resource-group $rg --vnet-name az-spk2-vnet --name subnet1 --route-table az-rt-spoke-to-hub -o none

echo "Creating UDR and associating it to the GatewaySubnet..."
# Create GatewaySubnet route table
az network route-table create --name az-rt-gwsubnet --resource-group $rg --location $location -o none
# Add a route to the route table
az network route-table route create --name Spk1Net --resource-group $rg --route-table-name az-rt-gwsubnet --address-prefix 10.0.1.0/24 --next-hop-type VirtualAppliance --next-hop-ip-address $hub_private_ip -o none
az network route-table route create --name Spk2Net --resource-group $rg --route-table-name az-rt-gwsubnet --address-prefix 10.0.2.0/24 --next-hop-type VirtualAppliance --next-hop-ip-address $hub_private_ip -o none
# Associate to GatewaySubnet on az-hub-vnet
az network vnet subnet update --resource-group $rg --vnet-name az-hub-vnet --name GatewaySubnet --route-table az-rt-gwsubnet -o none


### Create a storage account for VNET flow logs
echo Creating a storage account for VNET flow logs...
export stgname=stgflowlogs$RANDOM
az storage account create --name $stgname --resource-group $rg --location $location --sku Standard_LRS -o none

### Enable VNET Flow logs:
# Register Microsoft.Insights provider.
echo Registering Microsoft.Insights provider...
az provider register --namespace Microsoft.Insights -o none

# Create a VNet flow log.
echo Creating a VNet flow log...
az network watcher flow-log create --location $location --resource-group $rg --name VNetFlowLog-$rg --vnet  --storage-account $stgname --enabled true --retention 7 --no-wait

# Create a traffic analytics workspace.
echi Creating a traffic analytics workspace...
az monitor log-analytics workspace create --name vnetflowlogs-workspace --resource-group $rg --location $location -o none 

# Create a VNet flow log.
echo Creating VNet flow logs for az-hub-vnet, az-spk1-vnet and az-spk2-vnet...
az network watcher flow-log create --location $location --name hub-vnetflowlogs-$rg --resource-group $rg --vnet az-hub-vnet --storage-account $stgname --workspace vnetflowlogs-workspace --interval 10 --traffic-analytics true -o none
az network watcher flow-log create --location $location --name spk1-vnetflowlogs-$rg --resource-group $rg --vnet az-spk1-vnet --storage-account $stgname --workspace vnetflowlogs-workspace --interval 10 --traffic-analytics true -o none
az network watcher flow-log create --location $location --name spk2-vnetflowlogs-$rg --resource-group $rg --vnet az-spk2-vnet --storage-account $stgname --workspace vnetflowlogs-workspace --interval 10 --traffic-analytics true -o none

echo "Deployment hs been completed successfully."
# Add script ending time but hours, minutes and seconds
end=`date +%s`
runtime=$((end-start))
echo "Script finished at $(date)"
echo "Total script execution time: $(($runtime / 3600)) hours $((($runtime / 60) % 60)) minutes and $(($runtime % 60)) seconds."