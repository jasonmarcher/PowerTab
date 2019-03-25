$Completion_ModuleName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{}
    $Results = @()

    switch ($commandName) {
        "Get-Module" {
            if ($fakeBoundParameter["All"]) {
                $Parameters["All"] = $true
            }
            if ($fakeBoundParameter["ListAvailable"]) {
                $Parameters["ListAvailable"] = $true
            }
            $Results = Get-Module "$wordToComplete*" @Parameters
            break
        }
        "Import-Module" {
            if ($wordToComplete -notmatch '^\.') {
                $Results = FindModule "$wordToComplete*" | Select-Object @{Name = "Name"; Expression = {$_.BaseName}}
            }
            break
        }
        Default {
            $Results = Get-Module "$wordToComplete*"
        }
    }

    $Results | Sort-Object Name | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-Command" -ParameterName "Get-Command" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Get-Module" -ParameterName "Name" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Get-OperationValidation" -ParameterName "ModuleName" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Import-Module" -ParameterName "Name" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Invoke-OperationValidation" -ParameterName "ModuleName" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Remove-Module" -ParameterName "Name" -ScriptBlock $Completion_ModuleName
RegisterArgumentCompleter -CommandName "Update-Help" -ParameterName "Module" -ScriptBlock $Completion_ModuleName

$Completion_ModuleOrSnapin = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    ## TODO: Grab from session instead?
    (Get-Module -ListAvailable "$wordToComplete*") + (Get-PSSnapin "$wordToComplete*") | Sort-Object Name |
        NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Import-PSSession" -ParameterName "Module" -ScriptBlock $Completion_ModuleOrSnapin
RegisterArgumentCompleter -CommandName "Export-PSSession" -ParameterName "Module" -ScriptBlock $Completion_ModuleOrSnapin