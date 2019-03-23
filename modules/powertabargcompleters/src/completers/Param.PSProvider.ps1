$Completion_PSProviderName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSProvider "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -ParameterName "PSProvider" -ScriptBlock $Completion_PSProviderName