$Completion_EventEventIdentifier = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Event | NewTabItem -Value {$_.EventIdentifier} -Text {$_.EventIdentifier} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Event" -ParameterName "EventIdentifier" -ScriptBlock $Completion_EventEventIdentifier
RegisterArgumentCompleter -CommandName "Remove-Event" -ParameterName "EventIdentifier" -ScriptBlock $Completion_EventEventIdentifier

$Completion_EventSourceIdentifier = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Event "$Argument*" | Sort-Object SourceIdentifier |
        NewTabItem -Value {$_.SourceIdentifier} -Text {$_.SourceIdentifier} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Event" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Get-EventSubscriber" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "New-Event" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Register-EngineEvent" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Register-ObjectEvent" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Register-WmiEvent" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Register-CimIndicationEvent" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Remove-Event" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Unregister-Event" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier
RegisterArgumentCompleter -CommandName "Wait-Event" -ParameterName "SourceIdentifier" -ScriptBlock $Completion_EventSourceIdentifier

$Completion_EventEventName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    if ($fakeBoundParameter["InputObject"]) {
        Invoke-Expression $fakeBoundParameter["InputObject"] | Get-Member | 
            Where-Object {$_.MemberType -eq "Event" -and $_.Name -like "$wordToComplete*"} |
            NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
    }
}

RegisterArgumentCompleter -CommandName "Register-ObjectEvent" -ParameterName "EventName" -ScriptBlock $Completion_EventEventName

$Completion_WinEventListLog = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

    ## TODO: Make it easier to access detailed Microsoft-* logs?
    Get-WinEvent -ListLog "$wordToComplete*" @Parameters | NewTabItem -Value {$_.LogName} -Text {$_.LogName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "ListLog" -ScriptBlock $Completion_WinEventListLog

$Completion_WinEventListProvider = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

    Get-WinEvent -ListProvider "$wordToComplete*" @Parameters | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "ListProvider" -ScriptBlock $Completion_WinEventListProvider

$Completion_WinEventLogName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

    ## TODO: Make it easier to access detailed Microsoft-* logs?
    Get-WinEvent -ListLog "$wordToComplete*" @Parameters | NewTabItem -Value {$_.LogName} -Text {$_.LogName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "LogName" -ScriptBlock $Completion_WinEventLogName

$Completion_WinEventProviderName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

    Get-WinEvent -ListProvider "$wordToComplete*" @Parameters | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "ProviderName" -ScriptBlock $Completion_WinEventProviderName