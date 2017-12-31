## Modules
Register-TabExpansion "Get-InstalledModule" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $Modules = @(Get-InstalledModule "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Modules | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Module
            }
        }
    }
}.GetNewClosure()

Register-TabExpansion "Uninstall-Module" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $Modules = @(Get-InstalledModule "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Modules | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Module
            }
        }
    }
}.GetNewClosure()

Register-TabExpansion "Update-Module" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $Modules = @(Get-InstalledModule "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Modules | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Module
            }
        }
    }
}.GetNewClosure()

## PSRepository
Register-TabExpansion "Get-PSRepository" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $PSRepositories = @(Get-PSRepository "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $PSRepositories | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Repository
            }
        }
    }
}.GetNewClosure()

Register-TabExpansion "Set-PSRepository" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $PSRepositories = @(Get-PSRepository "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $PSRepositories | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Repository
            }
        }
    }
}.GetNewClosure()

Register-TabExpansion "Unregister-PSRepository" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            $PSRepositories = @(Get-PSRepository "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $PSRepositories | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Repository
            }
        }
    }
}.GetNewClosure()