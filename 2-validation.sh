



# On az-spk1-lxvm run the following command to generate traffic to az-hub-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.0.4 22; sleep 15; done

# On az-spk1-lxvm2 run the following command to generate traffic to az-spk1-lxvm:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done

# On onprem-lmxvm run the following command to generate traffic to az-spk1-lxvm1:
while true; do echo -n "$(date) "; netcat -v -z 10.0.1.4 22; sleep 15; done


# Check Network Watchet Traffic Analytics (it may take up to 15 minutes to start collecting data):

NTANetAnalytics
// Show all SSH traffic, use the filters below to narrow down
//| where SrcIp contains "10.0." or SrcIp contains "192.168." 
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| where DestPort == 22
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType, FlowDirection, FlowStatus
| sort by TimeGenerated desc 
#Other Examples

// IntraVNET
// Traffic between az-spk1-lxvm (10.0.1.4) and az-spk1-lxvm2 (10.0.1.5)
NTANetAnalytics
| where SrcIp contains "10.0.1.4" and DestIp contains "10.0.1.5"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType

// InterVNET
// Traffic between az-hub-lxvm (10.0.0.4) and az-spk1-lxvm (10.0.1.4)
NTANetAnalytics
| where SrcIp contains "10.0.0.4" and DestIp contains "10.0.1.4"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType

//On-premises to Azure
//Traffic between onprem-lxvm (192.168.100.4) and az-spk1-lxvm (10.0.1.4)
NTANetAnalytics
//On-premises
| where SrcIp contains "192.168.100.4" and DestIp contains "10.0.1.4"
//| where FlowEncryption == "Encrypted"
//| where FlowEncryption != "Encrypted"
| project TimeGenerated, SrcIp, DestIp, DestPort, FlowEncryption, FlowType
