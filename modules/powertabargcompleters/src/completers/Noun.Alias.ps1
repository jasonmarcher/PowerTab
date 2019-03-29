
$Completion_AliasName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Alias -Name "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
}

RegisterArgumentCompleter -CommandName "Export-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName
RegisterArgumentCompleter -CommandName "Get-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName
RegisterArgumentCompleter -CommandName "Set-Alias" -ParameterName "Name" -ScriptBlock $Completion_AliasName

$Completion_AliasScope = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "Global","Local","Script","0" | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Export-Alias" -ParameterName "Scope" -ScriptBlock $Completion_AliasScope
RegisterArgumentCompleter -CommandName "Get-Alias" -ParameterName "Scope" -ScriptBlock $Completion_AliasScope
RegisterArgumentCompleter -CommandName "Import-Alias" -ParameterName "Scope" -ScriptBlock $Completion_AliasScope
RegisterArgumentCompleter -CommandName "New-Alias" -ParameterName "Scope" -ScriptBlock $Completion_AliasScope
RegisterArgumentCompleter -CommandName "Set-Alias" -ParameterName "Scope" -ScriptBlock $Completion_AliasScope
