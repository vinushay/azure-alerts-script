$VMAlertsResults = @()
Write-Host "Connecting to Az"
Connect-AzAccount
$Subs = Get-AzSubscription

foreach ($Sub in $Subs) {

    if ($($Sub).name -eq "Azure.EDSNPE") {
        Write-Host "Processing Subscription:"  $($Sub).name ";" "Subscription Id:" $($Sub).Id
        Set-AzContext $Sub.id | Out-Null
        $ResourceGroups = Get-AzResourceGroup | select-Object -Property ResourceGroupName,@{N='AppName'; E={$_.Tags.AppName}} ,@{N='Application'; E={$_.Tags.Application}}
        foreach ($res in $ResourceGroups) {
            $resgrpNm = $res.ResourceGroupName
            Write-Host "Resource Group Name:" $resgrpNm
            $VMs = Get-AzResource -ResourceGroupName $resgrpNm -ResourceType "Microsoft.Compute/virtualMachines"
            foreach ($vm in $VMs){ 
                Write-Host "VM Name: " $vm.ResourceName #$vm.Id
                $VMAlerts = Get-AzAlert -TargetResourceId $Vm.Id 
                if ($vm.tags.Vendor -ne $databricks){
                    if ($null -eq $VMAlerts ){
                        $item = [PSCustomObject]@{
                            Subscription = $Sub.Name
                            ResourceGroupName = $resgrpNm
                            VMName = $vm.ResourceName
                            AlertName = "No Alerts Set"
                            AlertState = ""
                            AppName = $vm.tags.AppName
                            Application = $vm.tags.Application
                            Vendor = $vm.tags.Vendor
                            Owner=$vm.tags.Owner 
                        }
                        $VMAlertsResults += $item
                    }
                    elseif ($vm.tags.Vendor -ne $databricks) { 
                }
                else{
                    foreach ($ab in $VMAlerts){
                        Write-Host "Alert Name: " $ab.Name
                        $item = [PSCustomObject]@{
                            Subscription = $Sub.Name
                            ResourceGroupName = $resgrpNm
                            VMName = $vm.ResourceName
                            AlertName = $ab.Name
                            AlertState = $ab.State
                            AppName = $vm.tags.AppName
                            Application = $vm.tags.Application
                            Vendor = $vm.tags.Vendor
                            Owner= $vm.tags.Owner
                        }
                        $VMAlertsResults += $item
                    }
                    }
                }
            }
        }
        $VMAlertsResults | Export-Csv -Force -Path ".\AzureVM_Alerts_List-$(get-date -f yyyy-MM-dd-HHmm).csv"
    }
}