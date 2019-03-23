$Completion_PSSessionConfigurationName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSSessionConfiguration "$Argument*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Disable-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Enable-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Get-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Register-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Receive-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Set-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName
RegisterArgumentCompleter -CommandName "Unregister-PSSessionConfiguration" -ParameterName "Name" -ScriptBlock $Completion_PSSessionConfigurationName

$Completion_PSSessionConfigurationConfigurationTypeName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    ## TODO:
}

RegisterArgumentCompleter -CommandName "Register-PSSessionConfiguration" -ParameterName "ConfigurationTypeName" -ScriptBlock $Completion_PSSessionConfigurationConfigurationTypeName
RegisterArgumentCompleter -CommandName "Set-PSSessionConfiguration" -ParameterName "ConfigurationTypeName" -ScriptBlock $Completion_PSSessionConfigurationConfigurationTypeName
