<#  

.SYNOPSIS 
    Create a VM Image

.DESCRIPTION 


.NOTES 
    Author: Dennis Angeline (Dennis@FullScale180.com)

#> 

. .\Settings.ps1

#-----------------------------------------------------
# Import utilities module
#-----------------------------------------------------
Switch-AzureMode -Name AzureResourceManager
Import-Module AzureUtilities -Force -WarningAction SilentlyContinue 

Add-AzureAccountFromFile -UserName 'Dennis@Denscorp.onmicrosoft.com'
Set-AzureSubscription -SubscriptionId $subscriptionId -CurrentStorageAccountName $storageName

#-----------------------------------------------------
# Save the VM Image
#-----------------------------------------------------

$vm = Get-AzureVm -ResourceGroupName $rgName -Name $vmName

Stop-AzureVM -ResourceGroupName $rgName -Name $vmName

Set-AzureVM -ResourceGroupName $rgName -Name $vmName -Generalized

Save-AzureVMImage -ResourceGroupName $rgName -VMName $vmName -DestinationContainerName "private-images" -VHDNamePrefix "150821"
