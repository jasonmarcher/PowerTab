$Completion_PSSessionId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSSession | NewTabItem -Value {$_.Id} -Text {$_.Id} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Connect-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId
RegisterArgumentCompleter -CommandName "Disconnect-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId
RegisterArgumentCompleter -CommandName "Enter-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId
RegisterArgumentCompleter -CommandName "Get-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId
RegisterArgumentCompleter -CommandName "Receive-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId
RegisterArgumentCompleter -CommandName "Remove-PSSession" -ParameterName "Id" -ScriptBlock $Completion_PSSessionId

$Completion_PSSessionInstanceId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSSession | Where-Object {$_.InstanceId -like "$wordToComplete*"} |
        NewTabItem -Value {$_.InstanceId} -Text {$_.InstanceId} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Connect-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId
RegisterArgumentCompleter -CommandName "Disconnect-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId
RegisterArgumentCompleter -CommandName "Enter-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId
RegisterArgumentCompleter -CommandName "Get-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId
RegisterArgumentCompleter -CommandName "Receive-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId
RegisterArgumentCompleter -CommandName "Remove-PSSession" -ParameterName "InstanceId" -ScriptBlock $Completion_PSSessionInstanceId

$Completion_PSSessionName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSSession -Name "$wordToComplete*" | Sort-Object Name | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Connect-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName
RegisterArgumentCompleter -CommandName "Disconnect-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName
RegisterArgumentCompleter -CommandName "Enter-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName
RegisterArgumentCompleter -CommandName "Get-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName
RegisterArgumentCompleter -CommandName "Receive-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName
RegisterArgumentCompleter -CommandName "Remove-PSSession" -ParameterName "Name" -ScriptBlock $Completion_PSSessionName