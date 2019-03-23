$Completion_StrictVersion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "1.0","2.0","Latest" | Where-Object {$_ -like "$wordToComplete*"} | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Set-StrictMode" -ParameterName "Version" -ScriptBlock $Completion_StrictVersion