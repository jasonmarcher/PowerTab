@{
    ## Module Info
    ModuleVersion      = '1.0.0'
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
    VariablesToExport  = @('PowerTabConfig','PowerTabLog')
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
## 2018-01-XX - Version 1.0.0
- Added #5 - Support array functions for PS 3.0+
- Added #33 - Create basic help
- Added #37 - Add constructor syntax for New-Object
- Added #39 - Add a trace log
- Added #48 - Remove parameters already used for parameter completion
- Added #53 - Add Tab completion on Parameter of type Bool
- Added #54 - Tab expand assignments to variables containing enums
- Added #60 - Setup Wizard should have option to update user's profile
- Added #61 - Add Tab completion on Parameter of type Bool
- Added #62 - More support for WMI parameters
- Added #63 - Add support for Receive-Job -Location <TAB>
- Added #64 - Add support for *-Event -SourceIdentifier <TAB>
- Added #66 - Add support for Get-Command -Noun <TAB>
- Added #69 - Adding support for New-Object -ArgumentList (display syntax for constructors).
- Added #71 - PS v3, support finding workflow names
- Added #73 - Tab support for "Get-Help -Parameter"
- Added #74 - Support for calculated properties with ConvertTo-HTML
- Fixed #6 - In Core handler, avoid call with null CommandInfo
- Fixed #7 - Progress bar possibly hanging
- Fixed #24 - Detecting key state only works on Windows
- Fixed #25 - On closing the menu vertical lines may stay visible in the console
- Fixed #27 - Error with "Get-Content Function:TabExpansion" in PS V4
- Fixed #28 - PSv3: Pointless "Set-Location/Set-LocationEx" auto-complete shows up when I start up a new session
- Fixed #29 - Error in configuration if Profile doesn't exist
- Fixed #30 - Spelling error - LOAD POWERTAB WITH AN EXISTING CONFIG
- Fixed #31 - Powershell v3.0 - typo after tab return only the typo
- Fixed #32 - SHIFT-TAB doesn't work
- Fixed #34 - FileSystem expansion runs if core handler picks up a pattern but does not return a result
- Fixed #36 - Members of scriptblocks that are stored in variables are not shown
- Fixed #38 - Add option for expanding '~' in paths
- Fixed #40 - Broke completion of switch names [regression]
- Fixed #41 - Errors in PowerShell V3 CTP1
- Fixed #42 - Make command history tab completion consistent with default behavior
- Fixed #43 - Autocomplete for user functions stops working
- Fixed #44 - Members of static members of types not working quite right
- Fixed #46 - 0.99.6.0 Issue with networked "Modules" folder
- Fixed #47 - Quoting with Invoke has issues
- Fixed #49 - Alias pointing to script not visible
- Fixed #50 - t_<TAB> is showing "Dummy" types used internally by PowerTab
- Fixed #51 - PowerTab does not recognize automatic aliases for Get-* commands
- Fixed #52 - PowerTab suggesting wrong calculated property for Group-Object bug
- Fixed #57 - PowerTab sometimes forgetting drive name when expanding paths
- Fixed #58 - Add-TabExpansion allows duplicates to be added
- Fixed #65 - Improve understandability of options for some commands
- Fixed #67 - Another failure with completing from root of drive
- Fixed #68 - Internal errors in ConsoleLib
- Fixed #70 - Fixing major performance issue with PS v3. Only look for command names that are already loaded.
- Fixed #72 - Better handling of cleanup code in PS v3 environment
- Fixed - Don't break output for ParameterName handlers that output tab item objects

"@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
