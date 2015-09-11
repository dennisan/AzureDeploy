<#  

.SYNOPSIS 
    This script will create a VM instance from a VM Image

.DESCRIPTION 


.NOTES 
    Author: Dennis Angeline (Dennis@FullScale180.com)

#> 

. .\Scripts\Settings.ps1
Write-Host hello

#-----------------------------------------------------
# Import utilities module
#-----------------------------------------------------
Switch-AzureMode -Name AzureResourceManager

Import-Module AzureUtilities -Force -WarningAction SilentlyContinue 

#-----------------------------------------------------
# Authenticate
#-----------------------------------------------------
# Save-Password
Add-AzureAccountFromFile -UserName 'Dennis@Denscorp.onmicrosoft.com'

#-----------------------------------------------------
# Create Resource Group if it doesn't already exist
#-----------------------------------------------------

# Create the resource group
$rg = GetOrCreate-AzureResourceGroup -name $rgName -location $location -tags $tags


#-----------------------------------------------------
# Select Subscription & Storage
#-----------------------------------------------------
$storageAccount = GetOrCreate-AzureStorageAccount -name $storageName -type "Standard_LRS" -location $location -rgName $rgName 

Set-AzureSubscription -SubscriptionId $subscriptionId -CurrentStorageAccountName $storageName

#-----------------------------------------------------
# Create Virtual Network if it doesn't exist
#-----------------------------------------------------

# create the vnet (no subnets)
$vnet = GetOrCreate-AzureVirtualNetwork -name $vnetName -address $vnetAddress -rgName $rgName -location $location  -tags $tags

# Add App and Db subnets for this environment
$subcfg = GetOrCreate-AzureVirtualNetworkSubnetConfig -virtualNetwork $vnet -name $snetName -address $snetAddress

# Update the vnet with the subnets added above
$vnet = Set-AzureVirtualNetwork -VirtualNetwork $vnet
$subnet = Get-AzureVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet


#-----------------------------------------------------
# Create Public VIP Addresses if it doesn't exist
#-----------------------------------------------------

# Create the public VIP 
$vip = GetOrCreate-AzurePublicIpAddress  -name $vipName -domainName $domName -rgName $rgName -location $location -tags $tags

#-----------------------------------------------------
# Create the Load Balancer if it doesn't exist
#-----------------------------------------------------

# Define a name for the network interface
$nic = GetOrCreate-AzureNetworkInterface -Name $nicName -rgName $rgName -SubnetId $subnet.Id -PublicIpAddressId $vip.Id -location $location -tags $tags

#-----------------------------------------------------
# Create a new VM
#-----------------------------------------------------

# Define the spec for application server VMs
$vmSpec = @{ 
    
    # Define the app server OS configuration
    publisherName = 'MicrosoftWindowsServer';
    offerName = 'WindowsServer';
    skuName = '2012-R2-Datacenter';
    version = "latest";
    

    # Define the app server OS configuration
    vmSize = 'Standard_A3';
    vmUser = 'dennis';
    securePassword = ConvertTo-SecureString "P@ssword1" -AsPlainText -Force
    storageAccount = $storageName;

    disks = @()
}

#$vm = GetOrCreate-AzureVmFromSpec -rgName $rgName -vmName $vmName -vmSpec $vmSpec -envName $envName -nic $nic
