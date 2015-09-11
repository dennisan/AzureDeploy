#-----------------------------------------------------
# Import utilities module
#-----------------------------------------------------
Switch-AzureMode -Name AzureResourceManager

Import-Module -Name .\Utilities\AzureUtilities -Force -WarningAction SilentlyContinue 

#-----------------------------------------------------
# Authenticate
#-----------------------------------------------------
#Save-Password
Add-AzureAccountFromFile -UserName 'Dennis@Denscorp.onmicrosoft.com'

#-----------------------------------------------------
# Select the Subscription
#-----------------------------------------------------
$subscriptionId = '11dc728f-f13f-4a5e-ab73-a0a2563d7edd'  # MSDN Subscription
Select-AzureSubscription -SubscriptionId $subscriptionId 

#-----------------------------------------------------
# Create a new deployment
#-----------------------------------------------------
$deployName = "AzureDeploy"
$location = "westus"

$parameters = @{
    "customerPrefix" = "Jaguar";
    "environPrefix"  = "Prod";
}

$rgName = $parameters.customerPrefix

$rg = GetOrCreate-AzureResourceGroup -name $rgName -location $location -tags $tags

New-AzureResourceGroupDeployment -ResourceGroupName $rgName -Name $deployName -TemplateFile .\Templates\AzureDeploy-SharedResources.json -TemplateParameterObject $parameters 
New-AzureResourceGroupDeployment -ResourceGroupName $rgName -Name $deployName -TemplateFile .\Templates\AzureDeploy-LoadBalancedVirtualMachines.json -TemplateParameterObject $parameters 

 