$Completion_PSEdition = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Editions = @("Desktop","Core")

    $Editions | Where-Object {$_ -like "$wordToComplete*"} | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -ParameterName "PSEdition" -ScriptBlock $Completion_PSEdition