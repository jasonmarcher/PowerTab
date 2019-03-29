
$Completion_HelpName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    if ($wordToComplete -like "about_*") {
        $ProgressPreference = "SilentlyContinue" ## Suppress progress bars
        Get-Help "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
    } else {
        $CommandTypes = "Function","ExternalScript","Filter","Cmdlet","Alias"
        if ($PSVersionTable.PSVersion -ge "3.0") {
            $CommandTypes += "Workflow"
        }
        Get-Command "$wordToComplete*" -CommandType $CommandTypes | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
    }
}

RegisterArgumentCompleter -CommandName "Get-Help" -ParameterName "Name" -ScriptBlock $Completion_HelpName