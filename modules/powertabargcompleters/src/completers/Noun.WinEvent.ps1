$Completion_WinEventFilterHashTable = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    ('@{LogName="*"}','@{ProviderName="*"}','@{Keywords=""}','@{ID=""}','@{Level=""}') |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "FilterHashTable" -ScriptBlock $Completion_WinEventFilterHashTable

$Completion_WinEventListLog = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

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

    Get-WinEvent -ListLog "$wordToComplete*" @Parameters | NewTabItem -Value {$_.LogName} -Text {$_.LogName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "LogName" -ScriptBlock $Completion_WinEventLogName

$Completion_WinEventProviderName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}

    Get-WinEvent -ListProvider "$wordToComplete*" @Parameters | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WinEvent" -ParameterName "ProviderName" -ScriptBlock $Completion_WinEventProviderName