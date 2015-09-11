### Source VHD (West US) - anonymous access container ###
$srcUri = "https://prosppss.blob.core.windows.net/images/BaseVm-150821-osDisk.893e82e1-2819-4a81-b5e9-33618959a19c.vhd"

### Source Storage Account (West US) ###
$srcStorageAccount = "prosppss"
$srcStorageKey = "no15BILZeztpx69jF9x52wq0qQaw3rOGpJhxsY2TUp83N03lPqnoQOV/AxbyIAKICekG0es2qgEHV8H61vDjKw=="

### Create the source storage account context ### 
$srcContext = New-AzureStorageContext  –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey  

### Destination Storage Account (East US) ###
$destStorageAccount = "prodennisuswprdstnd"
$destStorageKey = "khvx75lXVZZt6KMPaopHiaLGM3vlm524B08M/jdhDGTtE2UE641fYxWyN03YAtaVzbQHlUMF/SdCznAZwanP6Q=="
 
### Create the destination context for authenticating the copy
$destContext = New-AzureStorageContext  –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey  
 
### Target Container Name
$containerName = "images"
 
### Create the target container in storage
New-AzureStorageContainer -Name $containerName -Context $destContext 
 
### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
$blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri `
                                    -SrcContext $srcContext `
                                    -DestContainer $containerName `
                                    -DestBlob "BaseVMImage.vhd" `
                                    -DestContext $destContext


### Retrieve the current status of the copy operation ###
$status = $blob1 | Get-AzureStorageBlobCopyState 
 
### Print out status ### 
$status 
 
### Loop until complete ###                                    
While($status.Status -eq "Pending"){
  $status = $blob1 | Get-AzureStorageBlobCopyState 
  Start-Sleep 10
  ### Print out status ###
  $status
}
