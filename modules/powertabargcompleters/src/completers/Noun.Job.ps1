$Completion_JobId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Job | NewTabItem -Value {$_.Id} -Text {$_.Id} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Debug-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Get-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Receive-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Remove-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Resume-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Stop-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Suspend-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId
RegisterArgumentCompleter -CommandName "Wait-Job" -ParameterName "Id" -ScriptBlock $Completion_JobId

$Completion_JobInstanceId = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Job | NewTabItem -Value {$_.InstanceId} -Text {$_.InstanceId} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Debug-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Get-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Receive-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Remove-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Resume-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Stop-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Suspend-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId
RegisterArgumentCompleter -CommandName "Wait-Job" -ParameterName "InstanceId" -ScriptBlock $Completion_JobInstanceId

$Completion_JobName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Job -Name "$wordToComplete*" | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Debug-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Get-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Receive-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Remove-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Resume-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Stop-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Suspend-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName
RegisterArgumentCompleter -CommandName "Wait-Job" -ParameterName "Name" -ScriptBlock $Completion_JobName

$Completion_JobJob = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    foreach ($Job in Get-Job -Name "$wordToComplete*") {
        '(Get-Job "{0}")' -f $Job.Name | Sort-Object | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
    }
}

RegisterArgumentCompleter -CommandName "Debug-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Receive-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Remove-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Resume-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Stop-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Suspend-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob
RegisterArgumentCompleter -CommandName "Wait-Job" -ParameterName "Job" -ScriptBlock $Completion_JobJob