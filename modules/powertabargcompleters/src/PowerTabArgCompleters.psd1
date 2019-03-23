@{
    ## Module Info
    ModuleVersion      = '1.0.0'
    Description        = "A module that enhances PowerShell's tab expansion."
    GUID               = '3ad03dca-ce9c-4a0b-92bc-36eee90828ae'
    # HelpInfoURI        = ''

    ## Module Components
    RootModule         = @("PowerTabArgCompleters.psm1")
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
            Tags = @("productivity","tabexpansion","tab-completion","Register-ArgumentCompleter")

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

- Modules
  - Microsoft.PowerShell.Core
  - Microsoft.PowerShell.Diagnostics

Detailed list available here:
https://github.com/jasonmarcher/PowerTab/milestone/1?closed=1

"@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
