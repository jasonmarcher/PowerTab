$Completion_PSDriveName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSDrive "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "LiteralName" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Get-PSDrive" -ParameterName "Name" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "LiteralName" -ScriptBlock $Completion_PSDriveName
RegisterArgumentCompleter -CommandName "Remove-PSDrive" -ParameterName "Name" -ScriptBlock $Completion_PSDriveName

RegisterArgumentCompleter -ParameterName "PSDrive" -ScriptBlock $Completion_PSDriveName