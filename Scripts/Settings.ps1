$subscriptionId = '11dc728f-f13f-4a5e-ab73-a0a2563d7edd'
$location       = 'West US'
$envName        = 'Leopard'    # be sure to change the vnet address
$vnetAddress    = "10.1.0.0/16"
$snetAddress    = "10.1.0.0/24"
$rgName         =  $envName
$storageName    = "${envName}store".ToLower()
$vnetName       = "${envName}-vnet"; 
$snetName       = "${envName}-sub1"; 

$vmInstance     =  3 
$vipName        = "${envName}-vip${vmInstance}"
$domName        = "${envName}-dom${vmInstance}".ToLower()
$nicName        = "${envName}-nic${vmInstance}"
$vmName         = "${envName}-vm${vmInstance}"
$tags           = @()
