@{
    ## Module Info
    ModuleVersion      = '1.0.0'
    Description        = "A module that enhances PowerShell's tab expansion."
    GUID               = '3ad03dca-ce9c-4a0b-92bc-36eee90828ae'
    # HelpInfoURI        = ''

    ## Module Components
    RootModule         = @("TabLib.psm1")
    ScriptsToProcess   = @()
    TypesToProcess     = @()
    FormatsToProcess   = @()
    FileList           = @()

    ## Public Interface
    CmdletsToExport    = @()
    FunctionsToExport  = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
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
