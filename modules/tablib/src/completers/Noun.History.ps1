$Completion_HistoryId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-History | NewTabItem -Value {$_.Id} -Text {$_.CommandLine} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Clear-History" -ParameterName "Id" -ScriptBlock $Completion_HistoryId
RegisterArgumentCompleter -CommandName "Get-History" -ParameterName "Id" -ScriptBlock $Completion_HistoryId
RegisterArgumentCompleter -CommandName "Invoke-History" -ParameterName "Id" -ScriptBlock $Completion_HistoryId