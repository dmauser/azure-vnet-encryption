### Check at the OS Level if the Accelerated Networking is enabled. That can be done in any VM on the hub and spoke networks
sudo lspci
# Expected output with Accelerated Networking enabled:
fcbc:00:02.0 Ethernet controller: Mellanox Technologies MT27800 Family [ConnectX-5 Virtual Function] (rev 80)
# Only Azure VMs have Accelerated Networking enabled, on-premises VMs does not have this feature.
# The expected output for VMs without Accelerated Networking is an empty output.

# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On az-spk2-lxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done


# Check Network Watchet Traffic Analytics (it may take up to 15 minutes to start collecting data):

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
