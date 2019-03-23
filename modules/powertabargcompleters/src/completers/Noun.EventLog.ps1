$Completion_EventLogCategory = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Categories = (
        @{'Id'='0';'Name'='None'},
        @{'Id'='1';'Name'='Devices'},
        @{'Id'='2';'Name'='Disk'},
        @{'Id'='3';'Name'='Printers'},
        @{'Id'='4';'Name'='Services'},
        @{'Id'='5';'Name'='Shell'},
        @{'Id'='6';'Name'='System Event'},
        @{'Id'='7';'Name'='Network'}
    )
    $Categories | Where-Object {$_.Name -like "$wordToComplete*"} | NewTabItem -Value {$_.Id} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Write-EventLog" -ParameterName "Category" -ScriptBlock $Completion_EventLogCategory

$Completion_EventLogLogName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-EventLog -List -AsString @Parameters | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Clear-EventLog" -ParameterName "LogName" -ScriptBlock $Completion_EventLogLogName
RegisterArgumentCompleter -CommandName "Get-EventLog" -ParameterName "LogName" -ScriptBlock $Completion_EventLogLogName
RegisterArgumentCompleter -CommandName "Limit-EventLog" -ParameterName "LogName" -ScriptBlock $Completion_EventLogLogName
RegisterArgumentCompleter -CommandName "Remove-EventLog" -ParameterName "LogName" -ScriptBlock $Completion_EventLogLogName
RegisterArgumentCompleter -CommandName "Write-EventLog" -ParameterName "LogName" -ScriptBlock $Completion_EventLogLogName