$Completion_PSHostProcessId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    ## TODO: Is it better to include window title?
    if ($wordToComplete -match '^[0-9]+$') {
        Get-PSHostProcessInfo @Parameters | Where-Object {$_.ProcessId.ToString() -like "$wordToComplete*"} |
            NewTabItem -Value {$_.ProcessId} -Text {"{0,-4} <# {1} #>" -f ([String]$_.ProcessId),$_.ProcessName} -ResultType ParameterValue
    } else {
        Get-PSHostProcessInfo @Parameters | Where-Object {$_.ProcessName -like "$wordToComplete*"} |
            NewTabItem -Value {$_.ProcessId} -Text {"{0,-4} <# {1} #>" -f ([String]$_.ProcessId),$_.ProcessName} -ResultType ParameterValue
    }
}

RegisterArgumentCompleter -CommandName "Enter-PSHostProcess" -ParameterName "Id" -ScriptBlock $Completion_PSHostProcessId
RegisterArgumentCompleter -CommandName "Get-PSHostProcessInfo" -ParameterName "Id" -ScriptBlock $Completion_PSHostProcessId

$Completion_PSHostProcessName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-PSHostProcessInfo -Name "$wordToComplete*" @Parameters | Get-Unique |
        NewTabItem -Value {$_.ProcessName} -Text {$_.ProcessName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Enter-PSHostProcess" -ParameterName "Name" -ScriptBlock $Completion_PSHostProcessName
RegisterArgumentCompleter -CommandName "Get-PSHostProcessInfo" -ParameterName "Name" -ScriptBlock $Completion_PSHostProcessName
