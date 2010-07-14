## PSClientManager

$ClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Select-Object -ExpandProperty Name | Sort-Object
        }
    }
}
$AddClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Where-Object {$_.State -eq "Disabled"} | Select-Object -ExpandProperty Name | Sort-Object
        }
    }
}
$RemoveClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Where-Object {$_.State -eq "Enabled"} | Select-Object -ExpandProperty Name | Sort-Object
        }
    }
}
    
Register-TabExpansion "Add-ClientFeature" $AddClientFeatureHandler -Type "Command"
Register-TabExpansion "Get-ClientFeature" $ClientFeatureHandler -Type "Command"
Register-TabExpansion "Get-ClientFeatureInfo" $ClientFeatureHandler -Type "Command"
Register-TabExpansion "Remove-ClientFeature" $RemoveClientFeatureHandler -Type "Command"
