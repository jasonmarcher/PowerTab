$Completion_VariableName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Variable "$wordToComplete*" -Scope "Global" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Clear-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Get-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Remove-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Set-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName