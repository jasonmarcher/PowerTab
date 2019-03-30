
$Completion_AliasName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Alias -Name "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
}

RegisterArgumentCompleter -CommandName "Export-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName
RegisterArgumentCompleter -CommandName "Get-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName
RegisterArgumentCompleter -CommandName "Set-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName