$Completion_VariableName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Variable "$wordToComplete*" -Scope "Global" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Clear-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Get-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Remove-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName
RegisterArgumentCompleter -CommandName "Set-Variable" -ParameterName "Name" -ScriptBlock $Completion_VariableName

$Completion_VariableScope = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "Global","Local","Script" | Where-Object {$_ -like "$wordToComplete*"} | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Clear-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Get-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "New-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Remove-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Set-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
