
Register-TabExpansion "New-MarkdownHelp" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Command' {
            $Commands = @(Get-Command "$Argument*" -CommandType Cmdlet,Function | Sort-Object Name)
            if ($Commands.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Commands | New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
            }
        }
        'Locale' {
            $TabExpansionHasOutput.Value = $true
            $QuoteSpaces.Value = $false
            [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
                Where-Object {$_.Name -like "$Argument*"} | Sort-Object Name |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
        }
        'Module' {
            $Modules = @(Get-Module "$Argument*" | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Modules | New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
            }
        }
        ## ModuleName ??
        ## ModuleGuid ??
    }
}.GetNewClosure()