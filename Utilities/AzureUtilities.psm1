# .SYNOPSIS
#   Template function

function GetOrCreate-AzureXxxx {
    Param
    (
        [String] $Name, 
        [String] $ResourceGroupName, 
        [String] $Location,
        [String] $Tags
    )

}

# .SYNOPSIS
#   Prompt for a password and save the result in an encrypted file

function Save-Password {

    Param
    (
        [String] $FilePath
    )
        
    $secure = Read-Host -AsSecureString "Enter your Azure organization ID password."
    $encrypted = ConvertFrom-SecureString -SecureString $secure

    if (!($FilePath)) {
        $FilePath = "${env:HOMEDRIVE}${env:HOMEPATH}\Azure-Creds.sec"
    }

    $result = Set-Content -Path $FilePath -Value $encrypted -PassThru
}


# .SYNOPSIS
#    Reads an encrypted password from FilePath and uses it to Add-AzureAccount
#    You must first save the password with Save-Password

function Add-AzureAccountFromFile {
    Param 
    (
        [String] $UserName, 
        [String] $FilePath
    )

    # save credentials for encrypted file (one time)
    #Save-Password -FilePath $credFilePath -PassThru

    if (!($FilePath)) {
        $FilePath = "${env:HOMEDRIVE}${env:HOMEPATH}\Azure-Creds.sec"
    }

    $securePassword = ConvertTo-SecureString (Get-Content -Path $FilePath )
    $cred = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

    Add-AzureAccount -Credential $cred
}


function GetOrCreate-AzureResourceGroup {
    Param 
    (
        $name, 
        $location,
        $tags
    )

    If (!(Test-AzureResourceGroup -ResourceGroupName $rgName)) 
    {
        New-AzureResourceGroup -Name $name -Location $location -Tag $tags

    } else {

        Get-AzureResourceGroup -Name $name
    }
}

function GetOrCreate-AzureStorageAccount {
    Param 
    (
        $name, 
        $rgName,
        $location,
        $type
    )

    if (!(Test-AzureResource -ResourceName $name -ResourceType "Microsoft.Storage/storageAccounts" -ResourceGroupName $rgName)) 
    {
        New-AzureStorageAccount -Name $name -ResourceGroupName $rgName -Location $location -Type $type 

    } else {

        Get-AzureStorageAccount -Name $name -ResourceGroupName $rgname
    }
}

function GetOrCreate-AzureVirtualNetwork {
    Param 
    (
        $name, 
        $address,
        $rgName,
        $location,
        $tags
    )

    if (!(Test-AzureResource -ResourceName $name -ResourceType "Microsoft.Network/virtualNetworks" -ResourceGroupName $rgName)) 
    {
        New-AzureVirtualNetwork -Name $name -ResourceGroupName $rgName -Location $location -AddressPrefix $address -Tag $tags 

    } else {

        Get-AzureVirtualNetwork -Name $name -ResourceGroupName $rgName
    }
}

function GetOrCreate-AzureVirtualNetworkSubnetConfig {
    Param 
    (
        $name, 
        $virtualNetwork,
        $address
    )

    
    $subnet = $virtualNetwork.Subnets | where {$_.Name -eq $name}

    if ($subnet -eq $null)
    {
        Add-AzureVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork -Name $name -AddressPrefix $address
        $subnet = $virtualNetwork.Subnets | where {$_.Name -eq $name}
    }
}

function GetOrCreate-AzureNetworkSecurityGroup {
    Param 
    (
        $name, 
        $rgName,
        $location,
        $tags
    )

    if (!(Test-AzureResource -ResourceName $nsgName -ResourceType "Microsoft.Network/networkSecurityGroups" -ResourceGroupName $rgName)) 
    {
        # Sample rule – currently permits RDP from all source IPs
        $nsgRule1 = New-AzureNetworkSecurityRuleConfig `
            -Name "allow-rdp-inbound" `
            -Description "Allow Inbound RDP" `
            -SourceAddressPrefix * `
            -DestinationAddressPrefix * `
            -Protocol Tcp `
            -SourcePortRange * `
            -DestinationPortRange 3389 `
            -Direction Inbound `
            -Access Allow `
            -Priority 100

        # Sample rule – currently permits HTTP from all source IPs
        $nsgRule2 = New-AzureNetworkSecurityRuleConfig `
            -Name "allow-http-inbound" `
            -Description "Allow Inbound HTTP" `
            -SourceAddressPrefix * `
            -DestinationAddressPrefix * `
            -Protocol Tcp `
            -SourcePortRange * `
            -DestinationPortRange 80 `
            -Direction Inbound `
            -Access Allow `
            -Priority 110

        # Create NSG using rules defined above
        New-AzureNetworkSecurityGroup `
            -Name $name `
            -ResourceGroupName $rgName `
            -Location $location `
            -SecurityRules $nsgRule1, $nsgRule2 `
            -Tag $tags

    } else {

        # Get NSG if already created

        Get-AzureNetworkSecurityGroup `
            -Name $nsgName `
            -ResourceGroupName $rgName

    }


}

function GetOrCreate-AzurePublicIpAddress {
    Param 
    (
        $name, 
        $rgName,
        $location,
        $domainName,
        $tags
    )


    if (!(Test-AzureResource -ResourceName $name -ResourceType "Microsoft.Network/publicIPAddresses" -ResourceGroupName $rgName)) 
    {
        New-AzurePublicIpAddress -Name $name -DomainNameLabel $domainName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic -Tag $tags

    } else {

        Get-AzurePublicIpAddress -Name $name -ResourceGroupName $rgName
    }
}

function GetOrCreate-AzureLoadBalancer {
    Param 
    (
        $name, 
        $rgName,
        $location,
        $vip,
        $tags
    )


    if (!(Test-AzureResource -ResourceName $name -ResourceType "Microsoft.Network/loadBalancers" -ResourceGroupName $rgName)) 
    {
        # Attach the lb to the frontend VIP
        $lbFeIpConfigName = "lb-feip"
        $lbFeIpConfig = New-AzureLoadBalancerFrontendIpConfig -Name $lbFeIpConfigName -PublicIpAddress $vip

        # Create a backend address pool for load-balanced traffic
        $lbBeIpPoolName = "lb-be-ip-pool"
        $lbBeIpPool = New-AzureLoadBalancerBackendAddressPoolConfig -Name $lbBeIpPoolName

        # Health Check Probe Config for HTTP
        $lbProbeName = "lb-probe"
        $lbProbe = New-AzureLoadBalancerProbeConfig `
            -Name $lbProbeName -RequestPath "/" -Protocol Http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

        # Use the FeIpConfig, BeIpPool and Probe to creeate a Load Balancer Rule for HTTP
        $lbRuleName = "lb-http"
        $lbRule = New-AzureLoadBalancerRuleConfig `
            -Name $lbRuleName -FrontendIpConfigurationId $lbFeIpConfig.Id -BackendAddressPoolId $lbBeIpPool.Id -ProbeId $lbProbe.Id `
            -Protocol Tcp -FrontendPort 80 -BackendPort 80 -LoadDistribution Default

        # Inbound NAT Rules for Remote Desktop per VM
        $lbInboundNatRules = @()

        # TODO - factor out the creation of RDP ports - we're using global variable instanceCount here
        for ($count = 1; $count -le $appServerSpec.instanceCount; $count++) 
        {
            $ruleName = "nat-rdp-${count}"
            $frontEndPort = 3389 + $count
            $backEndPort = 3389
            $lbInboundNatRules += New-AzureLoadBalancerInboundNatRuleConfig `
                -Name $ruleName -FrontendIpConfigurationId $lbFeIpConfig.Id -Protocol Tcp `
                -FrontendPort $frontEndPort -BackendPort $backEndPort
        }

        # Create Load Balancer using above config objects
        New-AzureLoadBalancer `
            -Name $name -ResourceGroupName $rgName -Location $location -FrontendIpConfiguration $lbFeIpConfig -Tag $tags `
            -BackendAddressPool $lbBeIpPool -Probe $lbProbe -InboundNatRule $lbInboundNatRules -LoadBalancingRule $lbRule

    } else {

        # Get Load Balancer if already created
        Get-AzureLoadBalancer -Name $name -ResourceGroupName $rgName

    }
}

function GetOrCreate-AzureNetworkInterface ($name, $subnetId, $publicIpAddressId, $rgName, $location, $tags, $nsgId, $lbRuleId, $lbPoolId) {

# Provide $name, $subnetId and either ($publicIpAddressId) Or ($nsgId, $lbRuleId, $lbPoolId)

    if (!(Test-AzureResource -ResourceName $name -ResourceType "Microsoft.Network/networkInterfaces" -ResourceGroupName $rgName)) {

        if ($nsgId -ne $null) {

            New-AzureNetworkInterface -Name $name -SubnetId $subnetId -ResourceGroupName $rgName -Location $location -Tag $tags `
                -NetworkSecurityGroupId $nsgId -LoadBalancerInboundNatRuleId $lbRuleId -LoadBalancerBackendAddressPoolId $lbPoolId 
                

        } else {

            New-AzureNetworkInterface -Name $name -SubnetId $subnetId -ResourceGroupName $rgName -Location $location -Tag $tags `
                -PublicIpAddressId $publicIpAddressId 

        }
    
    } else {

        Get-AzureNetworkInterface -Name $name -ResourceGroupName $rgName 

    }
}

function GetOrCreate-AzureVmFromSpec {
    Param 
    (
        $vmName, 
        $rgName,
        $vmSpec,
        $envName,
        $nic,
        $tags
    )


    if (!(Test-AzureResource -ResourceName $vmName -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupName $rgName)) {

        # Create an availability set for this environment
        $stdStorageAccount = Get-AzureStorageAccount -Name $vmSpec.storageAccount -ResourceGroupName $rgName

        # Create an availability set for this environment
        $avSetName = "${envName}-as"
        $avSet = New-AzureAvailabilitySet -Name $avSetName -ResourceGroupName $rgName -Location $location


        # Define OSDisk specs
        $osDiskLabel = "OSDisk"
        $osDiskName = "${vmName}-osdisk"
        $osDiskUri = $stdStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/${osDiskName}.vhd"
        $vmAdminCreds = New-Object System.Management.Automation.PSCredential ($vmSpec.vmUser, $vmSpec.securePassword);

        # Define VMConfig
        $vmConfig = New-AzureVMConfig -VMName $vmName -VMSize $vmSpec.vmSize -AvailabilitySetId $avSet.Id |
                    Set-AzureVMOperatingSystem -Windows -ComputerName $vmName -Credential $vmAdminCreds -ProvisionVMAgent -EnableAutoUpdate |
                    Set-AzureVMSourceImage -PublisherName $vmSpec.publisherName -Offer $vmSpec.offerName -Skus $vmSpec.skuName -Version $vmSpec.version |
                    Set-AzureVMOSDisk -Name $osDiskLabel -VhdUri $osDiskUri -CreateOption fromImage |
                    Add-AzureVMNetworkInterface -Id $nic.Id -Primary
        

        foreach ($disk in $vmSpec.disks) {
        
            $StorageAccount = Get-AzureStorageAccount -Name $disk.storageAccount -ResourceGroupName $rgName
            
            $lun = $disk.LUN
            $dataDiskName = "${vmName}-datadisk${lun}"
            $dataDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/${dataDiskName}.vhd"

            if ($disk.caching -eq $null) {

                $vmConfig = Add-AzureVMDataDisk -VM $vmConfig -Name $disk.label -DiskSizeInGB $disk.size -VhdUri $dataDiskURI -LUN $disk.LUN -CreateOption empty
            } else {

                $vmConfig = Add-AzureVMDataDisk -VM $vmConfig -Name $disk.label -DiskSizeInGB $disk.size -VhdUri $dataDiskURI -LUN $disk.LUN -CreateOption empty -Caching $disk.caching
            }
        }        
        
        
        # Create new VM
        New-AzureVM -VM $vmConfig -ResourceGroupName $rgName -Location $location -Tags $tags

    } else {
  
        # Get the VM if already provisioned
        Get-AzureVM -Name $vmName -ResourceGroupName $rgName
    }
}

function GetOrCreate-AzureVmFromSpec2 {
    Param 
    (
        $vmName, 
        $rgName,
        $vmSpec,
        $envName,
        $nic,
        $tags
    )


    if (!(Test-AzureResource -ResourceName $vmName -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupName $rgName)) {

        # Create an availability set for this environment
        $stdStorageAccount = Get-AzureStorageAccount -Name $vmSpec.storageAccount -ResourceGroupName $rgName

        # Create an availability set for this environment
        $avSetName = "${envName}-as"
        $avSet = New-AzureAvailabilitySet -Name $avSetName -ResourceGroupName $rgName -Location $location


        # Define OSDisk specs
        $osDiskLabel = "OSDisk"
        $osDiskName = "${vmName}-osdisk"

        #$osDiskUri = $stdStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/${osDiskName}.vhd"
        $osVhdUri =  "https://cheetastore.blob.core.windows.net/vmcontainer9407220f-eb8b-42e2-b50b-96817a31603f/osDisk.9407220f-eb8b-42e2-b50b-96817a31603f.vhd"
        $osImageUri = "https://cheetastore.blob.core.windows.net/system/Microsoft.Compute/Images/private-images/150821-osDisk.2b2f6f59-bbee-409a-94ab-73d00b7f34d5.vhd"

        $vmAdminCreds = New-Object System.Management.Automation.PSCredential ($vmSpec.vmUser, $vmSpec.securePassword);

        # Define VMConfig
        $vmConfig = New-AzureVMConfig -VMName $vmName -VMSize $vmSpec.vmSize -AvailabilitySetId $avSet.Id |
                    Set-AzureVMOperatingSystem -Windows -ComputerName $vmName -Credential $vmAdminCreds -ProvisionVMAgent -EnableAutoUpdate |
                    #Set-AzureVMSourceImage -PublisherName $vmSpec.publisherName -Offer $vmSpec.offerName -Skus $vmSpec.skuName -Version $vmSpec.version |
                    Set-AzureVMOSDisk -Name $osDiskLabel -CreateOption fromImage  -Windows -VhdUri $osVhdUri  | # -SourceImageUri $osImageUri
                    Add-AzureVMNetworkInterface -Id $nic.Id -Primary
        

        foreach ($disk in $vmSpec.disks) {
        
            $StorageAccount = Get-AzureStorageAccount -Name $disk.storageAccount -ResourceGroupName $rgName
            
            $lun = $disk.LUN
            $dataDiskName = "${vmName}-datadisk${lun}"
            $dataDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/${dataDiskName}.vhd"

            if ($disk.caching -eq $null) {

                $vmConfig = Add-AzureVMDataDisk -VM $vmConfig -Name $disk.label -DiskSizeInGB $disk.size -VhdUri $dataDiskURI -LUN $disk.LUN -CreateOption empty
            } else {

                $vmConfig = Add-AzureVMDataDisk -VM $vmConfig -Name $disk.label -DiskSizeInGB $disk.size -VhdUri $dataDiskURI -LUN $disk.LUN -CreateOption empty -Caching $disk.caching
            }
        }        
        
        
        # Create new VM
        New-AzureVM -VM $vmConfig -ResourceGroupName $rgName -Location $location -Tags $tags

    } else {
  
        # Get the VM if already provisioned
        Get-AzureVM -Name $vmName -ResourceGroupName $rgName
    }
}
