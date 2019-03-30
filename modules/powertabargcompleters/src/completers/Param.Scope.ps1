$Completion_ParamScope = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "Global","Local","Script","0" | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Export-Alias" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "Get-Alias" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "Import-Alias" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "New-Alias" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "Set-Alias" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope

RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "New-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_ParamScope

RegisterArgumentCompleter -CommandName "Clear-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Get-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "New-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Remove-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope
RegisterArgumentCompleter -CommandName "Set-Variable" -ParameterName "Scope" -ScriptBlock $Completion_VariableScope