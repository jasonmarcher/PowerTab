$Completion_ProcessId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    if ($wordToComplete -match '^[0-9]+$') {
        Get-Process @Parameters | Where-Object {$_.Id.ToString() -like "$wordToComplete*"} |
            NewTabItem -Value {$_.Id} -Text {"{0,-4} <# {1} #>" -f ([String]$_.Id),$_.Name} -ResultType ParameterValue
    } else {
        Get-Process @Parameters | Where-Object {$_.Name -like "$wordToComplete*"} |
            NewTabItem -Value {$_.Id} -Text {"{0,-4} <# {1} #>" -f ([String]$_.Id),$_.Name} -ResultType ParameterValue
    }
}

RegisterArgumentCompleter -CommandName "Debug-Process" -ParameterName "Id" -ScriptBlock $Completion_ProcessId
RegisterArgumentCompleter -CommandName "Get-Process" -ParameterName "Id" -ScriptBlock $Completion_ProcessId
RegisterArgumentCompleter -CommandName "Stop-Process" -ParameterName "Id" -ScriptBlock $Completion_ProcessId
RegisterArgumentCompleter -CommandName "Wait-Process" -ParameterName "Id" -ScriptBlock $Completion_ProcessId

$Completion_ProcessName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-Process -Name "$wordToComplete*" @Parameters | Get-Unique |
        NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Debug-Process" -ParameterName "Name" -ScriptBlock $Completion_ProcessName
RegisterArgumentCompleter -CommandName "Get-Process" -ParameterName "Name" -ScriptBlock $Completion_ProcessName
RegisterArgumentCompleter -CommandName "Stop-Process" -ParameterName "Name" -ScriptBlock $Completion_ProcessName
RegisterArgumentCompleter -CommandName "Wait-Process" -ParameterName "Name" -ScriptBlock $Completion_ProcessName
