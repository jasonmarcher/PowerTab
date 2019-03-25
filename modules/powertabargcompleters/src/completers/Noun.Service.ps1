$Completion_ServiceDisplayName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-Service -DisplayName "*$wordToComplete*" @Parameters |
        NewTabItem -Value {$_.DisplayName} -Text {$_.DisplayName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName
RegisterArgumentCompleter -CommandName "Restart-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName
RegisterArgumentCompleter -CommandName "Resume-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName
RegisterArgumentCompleter -CommandName "Start-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName
RegisterArgumentCompleter -CommandName "Stop-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName
RegisterArgumentCompleter -CommandName "Suspend-Service" -ParameterName "DisplayName" -ScriptBlock $Completion_ServiceDisplayName

$Completion_ServiceName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-Service -Name "$wordToComplete*" @Parameters | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "New-Service" -ParameterName "DependsOn" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Restart-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Resume-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Set-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Start-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Stop-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
RegisterArgumentCompleter -CommandName "Suspend-Service" -ParameterName "Name" -ScriptBlock $Completion_ServiceName
