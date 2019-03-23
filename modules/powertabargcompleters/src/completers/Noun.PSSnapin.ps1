$Completion_PSSnapinName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Parameters = @{"ErrorAction" = "SilentlyContinue"}
    $Snapins = @()

    switch ($commandName) {
        "Add-PSSnapin" {
            $Loaded = @(Get-PSSnapin)
            $Snapins = Get-PSSnapin "$wordToComplete*" -Registered @Parameters | Where-Object {$Loaded -notcontains $_}
            break
        }
        "Remove-PSSnapin" {
            $Loaded = @(Get-PSSnapin)
            $Snapins = Get-PSSnapin "$wordToComplete*" @Parameters | Where-Object {$Loaded -contains $_}
            break
        }
        Default {
            if ($fakeBoundParameter["Registered"]) {
                $Parameters["Registered"] = $true
            }
            $Snapins = Get-PSSnapin "$wordToComplete*" @Parameters
        }
    }

    $Snapins | Sort-Object Name | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Add-PSSnapin" -ParameterName "Name" -ScriptBlock $Completion_PSSnapinName
RegisterArgumentCompleter -CommandName "Get-PSSnapin" -ParameterName "Name" -ScriptBlock $Completion_PSSnapinName
RegisterArgumentCompleter -CommandName "Remove-PSSnapin" -ParameterName "Name" -ScriptBlock $Completion_PSSnapinName