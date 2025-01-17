# Lab: Azure Virtual Network Encryption

## Intro

This a lab to demonstrate how to enable encryption for Azure Virtual Network and validate it using Traffic Analytics.
Below are the links to the official documentation to help you understand the concepts and the steps to enable encryption for Azure Virtual Network.

- [What is Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-overview)
- [Frequently asked questions for Azure Virtual Network encryption?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-faq)
- [Create a virtual network with encryption](https://learn.microsoft.com/en-us/azure/virtual-network/how-to-create-encryption)

## Lab Scenario

This lab build a Hub and Spoke and on-premises

Step 1 - Run the base lab deployment script

```bash
curl -sL https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/1-deploy.sh | bash
```
On this step it will prompt you for username and password.

Step 2 - Before enable vNET encryption, let's validate the traffic between the VMs.

Step 3 - Enable vNET encryption

```bash
curl -sL https://raw.githubusercontent.com/dmauser/azure-vnet-encryption/refs/heads/main/2-enable-vnet-encryption.sh | bash
```
