$Completion_PSDriveName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSDrive "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "LiteralName" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "Name" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "LiteralName" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "Name" -ScriptBlock $Completion_PSDriveName

RegisterArgumentCompleter -ParameterName "PSDrive" -ScriptBlock $Completion_PSDriveName

$Completion_PSDriveScope = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "Global","Local","Script","0" | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_PSDriveScope
RegisterArgumentCompleter -CommandName "New-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_PSDriveScope
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "Scope" -ScriptBlock $Completion_PSDriveScope
