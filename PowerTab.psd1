@{
    ## Module Info
    ModuleVersion      = '1.1.0'
    Description        = "A module that enhances PowerShell's tab expansion."
    GUID               = '64c85865-df87-4bd6-bccd-ea294dc335b3'
    # HelpInfoURI        = ''

    ## Module Components
    RootModule         = @("PowerTab.psm1")
    ScriptsToProcess   = @()
    TypesToProcess     = @()
    FormatsToProcess   = @("TabExpansion.Format.ps1xml")
    FileList           = @()

    ## Public Interface
    CmdletsToExport    = ''
    FunctionsToExport  = @("Get-TabExpansion","Add-TabExpansion","Remove-TabExpansion","Add-TabExpansionComputer","Remove-TabExpansionComputer",
"Update-TabExpansionCom","Add-TabExpansionType","Update-TabExpansionType","Update-TabExpansionWmi","Invoke-TabExpansion",
"Register-TabExpansion","New-TabItem","New-TabExpansionConfig","Import-TabExpansionConfig","Export-TabExpansionConfig",
"New-TabExpansionDatabase","Import-TabExpansionDataBase","Export-TabExpansionDatabase","Update-TabExpansionDataBase",
"Import-TabExpansionTheme","Export-TabExpansionTheme","Invoke-TabExpansionEditor","Find-TabExpansionType",
"Resolve-TabExpansionParameterValue")
    VariablesToExport  = @('PowerTabConfig')
    AliasesToExport    = @("ate","gte","itee","rgte","rte","udte")
    # DscResourcesToExport = @()
    # DefaultCommandPrefix = ''

    ## Requirements
    # CompatiblePSEditions = @()
    PowerShellVersion      = '3.0'
    # PowerShellHostName     = ''
    # PowerShellHostVersion  = ''
    RequiredModules        = @()
    RequiredAssemblies     = @()
    ProcessorArchitecture  = 'None'
    DotNetFrameworkVersion = '2.0'
    CLRVersion             = '2.0'

    ## Author
    Author             = 'Jason Archer'
    CompanyName        = ''
    Copyright          = ''

    ## Private Data
    PrivateData        = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @("productivity","tabexpansion","tab-completion")

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/jasonmarcher/PowerTab'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @"
## 2018-09-21 - Version 1.1.0

Features:

- Add support for new Cmdlets
  - PlatyPS module
  - CIM Cmdlets
  - Connect-PSSession and Disconnect-PSSession
  - Remove-Event
- Added support for more Parameters
  - *-Alias `-Definition` and `-Value`
  - Trace-Command `-Command`
  - Parameters of type `[System.Text.Encoding]`
- Added basic support for OpenSSH on Windows command line options

Bug Fixes:

- Fix error on first import of PowerTab (regression in 1.0.0)
- ConsoleList double boarder setting now works
- Fixed bug with completing paths on their own (particularly `~\` and `.\`)
- Fixed completing cmdlets when using fully qualified names (example: `PowerTab\Add-TabExpansion`)

Detailed list available here:
https://github.com/jasonmarcher/PowerTab/milestone/2?closed=1

## 2018-01-29 - Version 1.0.0

Features:

- Some compatibility changes for PowerShell Core
  - Removed Intellisense Item Selector
- Console history from PSReadline used if available
- Added support for new parameters
  - Workflow names
  - Get-Help -Parameter
  - *-Event -SourceIdentifier
  - Get-Command -Noun
  - Receive-Job -Location
  - WMI parameters
  - New-Object -ArgumentList (display syntax for constructors)
  - Parameters of type Bool
  - ConvertTo-HTML calculated properties
- Added support for assignments to enum variables
- Added array functions from PowerShell v3.0
- Remove parameters already used for parameter completion
- New History and Trace logs for PowerTab usage
- ConsoleList
  - New color theme based on CMD

Bug Fixes:

- General compatiblity fixes with latest PowerShell versions
  - Fix display issue with TrueType fonts
  - Only loaded commands are shown for PowerShell 3.0 and later
- Compatibility fixes with PowerShell Core and non-Windows OSes
  - NOTE: This is not fully tested but full compatibility is a goal
- Consistency fixes for behavior compared to default PowerShell tab expansion
  - Many small fixes for provider paths
- Get-Command <TAB> now includes scripts from `$env:PATH
- PowerTab now recognizes automatic aliases for Get-* commands

Detailed list available here:
https://github.com/jasonmarcher/PowerTab/milestone/1?closed=1

"@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
