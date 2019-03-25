$Completion_PrinterName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-CimInstance -ClassName "Win32_Printer" -Filter "Name LIKE '$wordToComplete%'" |
        NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Out-Printer" -ParameterName "Name" -ScriptBlock $Completion_PrinterName