## PSClientManager

$ClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Sort-Object Name | New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
        }
    }
}
$AddClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Where-Object {$_.State -eq "Disabled"} | Sort-Object Name |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
        }
    }
}
$RemoveClientFeatureHandler = {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-ClientFeature "$Argument*" | Where-Object {$_.State -eq "Enabled"} | Sort-Object Name |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
        }
    }
}
    
Register-TabExpansion "Add-ClientFeature" $AddClientFeatureHandler -Type "Command"
Register-TabExpansion "Get-ClientFeature" $ClientFeatureHandler -Type "Command"
Register-TabExpansion "Get-ClientFeatureInfo" $ClientFeatureHandler -Type "Command"
Register-TabExpansion "Remove-ClientFeature" $RemoveClientFeatureHandler -Type "Command"
