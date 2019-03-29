$Completion_Command = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $CommandTypes = "Function","Filter","Cmdlet"
    if ($PSVersionTable.PSVersion -ge "3.0") {
        $CommandTypes += "Workflow"
    }
    Get-Command "$wordToComplete*" -CommandType $CommandTypes |
        NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
}

RegisterArgumentCompleter -CommandName "Get-Alias" -ParameterName "Definition" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "Get-Job" -ParameterName "Command" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "Get-PSBreakpoint" -ParameterName "Command" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "New-Alias" -ParameterName "Value" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "Set-Alias" -ParameterName "Value" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "Set-PSBreakpoint" -ParameterName "Command" -ScriptBlock $Completion_Command
RegisterArgumentCompleter -CommandName "Trace-Command" -ParameterName "Command" -ScriptBlock $Completion_Command

$Completion_CommandAll = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $CommandTypes = "Function","ExternalScript","Filter","Cmdlet"
    if ($PSVersionTable.PSVersion -ge "3.0") {
        $CommandTypes += "Workflow"
    }
    Get-Command "$wordToComplete*" -CommandType $CommandTypes |
        NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
}

$Completion_CommandNoun = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $CommandTypes = "Function","Filter","Cmdlet"
    if ($PSVersionTable.PSVersion -ge "3.0") {
        $CommandTypes += "Workflow"
    }
    Get-Command -CommandType $CommandTypes | Where-Object {$_.Name -match "^[^-]+-(?<Noun>$wordToComplete.*)"} |
        . {process{$Matches.Noun}} | Sort-Object -Unique | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Command" -ParameterName "Noun" -ScriptBlock $Completion_CommandNoun

$Completion_CommandVerb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Verb "$wordToComplete*" | Sort-Object Verb | NewTabItem -Value {$_.Verb} -Text {$_.Verb} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Command" -ParameterName "Verb" -ScriptBlock $Completion_CommandVerb