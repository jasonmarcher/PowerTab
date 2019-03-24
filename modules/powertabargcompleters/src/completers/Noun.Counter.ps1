$Completion_Counter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-Counter -ListSet * @Parameters | Where-Object {$_.PathsWithInstances -like "*$wordToComplete*"} |
        Sort-Object PathsWithInstances | NewTabItem -Value {$_.PathsWithInstances} -Text {$_.PathsWithInstances} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Counter" -ParameterName "Counter" -ScriptBlock $Completion_Counter
RegisterArgumentCompleter -CommandName "Import-Counter" -ParameterName "Counter" -ScriptBlock $Completion_Counter

$Completion_CounterSet = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}

    Get-Counter -ListSet "$wordToComplete*" @Parameters | NewTabItem -Value {$_.CounterSetName} -Text {$_.CounterSetName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Counter" -ParameterName "ListSet" -ScriptBlock $Completion_CounterSet
RegisterArgumentCompleter -CommandName "Import-Counter" -ParameterName "ListSet" -ScriptBlock $Completion_CounterSet

$Completion_CounterFormat = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "CSV", "TSV", "BLG" | Where-Object {$_ -like "$wordToComplete*"} | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Export-Counter" -ParameterName "FileFormat" -ScriptBlock $Completion_CounterFormat