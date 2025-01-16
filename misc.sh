# Loop script to resize all vms that contains az- to Standard_D2d_v4
az vm list -g $rg --query "[?contains(name, 'az-')].name" -o tsv | while read vm_name; do
    echo "Resizing VM: $vm_name"
    az vm resize --resource-group $rg --name $vm_name --size Standard_D2d_v4 -o none
done