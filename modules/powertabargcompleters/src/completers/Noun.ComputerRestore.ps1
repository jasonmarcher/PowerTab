$Completion_ComputerRestoreDrive = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-PSDrive -PSProvider FileSystem "$wordToComplete*" |
        NewTabItem -Value {$_.Root} -Text {$_.Root} -ResultType ProviderContainer
}

RegisterArgumentCompleter -CommandName "Disable-ComputerRestore" -ParameterName "Drive" -ScriptBlock $Completion_ComputerRestoreDrive
RegisterArgumentCompleter -CommandName "Enable-ComputerRestore" -ParameterName "Drive" -ScriptBlock $Completion_ComputerRestoreDrive

$Completion_ComputerRestorePoint = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    foreach ($Point in Get-ComputerRestorePoint -ErrorAction Stop) {
        if ($Point.Description.Length -gt 50) {
            $Description = $Point.Description.SubString(0, 50)
        } else {
            $Description = $Point.Description
        }
        $Text = "{0}: {1} ({2})" -f $Point.SequenceNumber,[DateTime]::ParseExact($Point.CreationTime, "yyyyMMddHHmmss.ffffff-000", $null),$Description
        NewTabItem -Value $Point.SequenceNumber -Text $Text -ResultType ParameterValue
    }
}

RegisterArgumentCompleter -CommandName "Get-ComputerRestorePoint" -ParameterName "RestorePoint" -ScriptBlock $Completion_ComputerRestorePoint
RegisterArgumentCompleter -CommandName "Restore-Computer" -ParameterName "RestorePoint" -ScriptBlock $Completion_ComputerRestorePoint
