@{
    ## Module Info
    ModuleVersion      = '1.0.0'
    Description        = "A library of argument completers."
    GUID               = '3ad03dca-ce9c-4a0b-92bc-36eee90828ae'
    # HelpInfoURI        = ''

    ## Module Components
    RootModule         = @("PTAG.psm1")
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
            Tags = @("powertab","productivity","tabexpansion","tab-completion","Register-ArgumentCompleter")

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
  - International
  - Microsoft.PowerShell.Core
  - Microsoft.PowerShell.Diagnostics
  - Microsoft.PowerShell.Management
  - Microsoft.PowerShell.Operation.Validation
  - Microsoft.PowerShell.Utility

Detailed list of supported parameters available here:
https://github.com/jasonmarcher/PowerTab/blob/master/Docs/ptag/FeatureList.md

"@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
