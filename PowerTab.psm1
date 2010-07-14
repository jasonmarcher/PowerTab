

param()

$ConfigurationPathParam = ""

. {
	[CmdletBinding(SupportsShouldProcess = $false,
		SupportsTransactions = $false,
		ConfirmImpact = "None",
		DefaultParameterSetName = "")]
    param(
		[Parameter(Position = 0)]
        [String]
        $ConfigurationPath = ""
    )

    if ($ConfigurationPath) {
        $script:ConfigurationPathParam = $ConfigurationPath
    } elseif ($PrivateData = (Get-Module -ListAvailable $PSCmdlet.MyInvocation.MyCommand.Module.Name).PrivateData) {
        $script:ConfigurationPathParam = $PrivateData
    }
} @args

## Load forms library when not loaded 
if (-not ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.ManifestModule -like "System.Windows.Forms*"})) {
    [Void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
}

## Load shares library
if (-not ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.ManifestModule -like "Shares.*"})) {
    [Void][System.Reflection.Assembly]::LoadFile((Join-Path $PSScriptRoot "Shares.dll"))
}

#########################
## Cleanup
#########################

$OldTabExpansion = Get-Content Function:TabExpansion
$Module = $MyInvocation.MyCommand.ScriptBlock.Module 
$Module.OnRemove = {
    Set-Content Function:\TabExpansion -Value $OldTabExpansion
}


#########################
## Private properties
#########################

$dsTabExpansionDatabase = New-Object System.Data.DataSet

$dsTabExpansionConfig = New-Object System.Data.DataSet

$TabExpansionCommandRegistry = @{}

$TabExpansionParameterRegistry = @{}

$TabExpansionCommandInfoRegistry = @{}

$TabExpansionParameterNameRegistry = @{}


#########################
## Public properties
#########################

$PowerTabConfig = New-Object System.Object


#########################
## Functions
#########################

Import-Module (Join-Path $PSScriptRoot "Lerch.PowerShell.dll")
. (Join-Path $PSScriptRoot "TabExpansionResources.ps1")
Import-LocalizedData -BindingVariable "Resources" -FileName "Resources"
. (Join-Path $PSScriptRoot "TabExpansionCore.ps1")
. (Join-Path $PSScriptRoot "TabExpansionLib.ps1")
. (Join-Path $PSScriptRoot "TabExpansionUtil.ps1")
. (Join-Path $PSScriptRoot "TabExpansionHandlers.ps1")
. (Join-Path $PSScriptRoot "ConsoleLib.ps1")
Get-ChildItem (Join-Path $PSScriptRoot "Handlers\*.ps1") | ForEach-Object {. $_.FullName}


#########################
## Initialization code
#########################

if ($ConfigurationPathParam) {
    if ((Test-Path $ConfigurationPathParam) -or (
            ($ConfigurationPathParam -eq "IsolatedStorage") -and (Test-IsolatedStoragePath "PowerTab\PowerTabConfig.xml"))) {
        Initialize-PowerTab $ConfigurationPathParam
    } elseif (Test-Path (Join-Path $PSScriptRoot $ConfigurationPathParam)) {
        Initialize-PowerTab (Join-Path $PSScriptRoot $ConfigurationPathParam)
    } else {
        ## Config specified, but does not exist

        ## Create config and database
        New-TabExpansionConfig $ConfigurationPathParam
        CreatePowerTabConfig
        New-TabExpansionDatabase

        ## Update database
        Update-TabExpansionDataBase -Confirm

        ## Export changes
        Export-TabExpansionConfig
        Export-TabExpansionDatabase
    }
} else {
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.global_choice_yes
    $No = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.global_choice_no
    $YesNoChoices = [System.Management.Automation.Host.ChoiceDescription[]]($No,$Yes)

    ## Launch setup wizard?
    $Answer = $Host.UI.PromptForChoice($Resources.setup_wizard_caption, $Resources.setup_wizard_message, $YesNoChoices, 1)
    if ($Answer) {
        ## Ask for location to place config and database
        $ProfileDir = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.setup_wizard_choice_profile_directory
        $InstallDir = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.setup_wizard_choice_install_directory
        $AppDataDir = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.setup_wizard_choice_appdata_directory
        $IsoStorageDir = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.setup_wizard_choice_isostorage_directory
        $OtherDir = New-Object System.Management.Automation.Host.ChoiceDescription $Resources.setup_wizard_choice_other_directory
        $LocationChoices = [System.Management.Automation.Host.ChoiceDescription[]]($ProfileDir,$InstallDir,$AppDataDir,$IsoStorageDir,$OtherDir)
        $Answer = $Host.UI.PromptForChoice($Resources.setup_wizard_config_location_caption, $Resources.setup_wizard_config_location_message, $LocationChoices, 0)
        $SetupConfigurationPath = switch ($Answer) {
            0 {Split-Path $Profile}
            1 {$PSScriptRoot}
            2 {Join-Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)) "PowerTab"}
            3 {"IsolatedStorage"}
            4 {
                $Path = Read-Host $Resources.setup_wizard_other_directory_prompt
                while ((-not $Path) -or -not (Test-Path -IsValid $Path)) {
                    ## TODO: Maybe write-error instead?
                    Write-Host $Resources.setup_wizard_err_path_not_valid -ForegroundColor $Host.PrivateData.ErrorForegroundColor `
                        -BackgroundColor $Host.PrivateData.ErrorBackgroundColor
                    $Path = Read-Host $Resources.setup_wizard_other_directory_prompt
                }
                $Path
            }
        }

        ## Create config in chosen location
        if ($SetupConfigurationPath -eq "IsolatedStorage") {
            New-TabExpansionConfig $SetupConfigurationPath
        } else {
            New-TabExpansionConfig (Join-Path $SetupConfigurationPath "PowerTabConfig.xml")
        }
        CreatePowerTabConfig

        ## Profile text
        ## TODO: Ask to update profile
        $ProfileText = @"

<############### Start of PowerTab Initialization Code ########################
    Added to profile by PowerTab setup for loading of custom tab expansion.
    Import other modules after this, they may contain PowerTab integration.
#>

Import-Module "PowerTab" -ArgumentList "$(Join-Path $SetupConfigurationPath "PowerTabConfig.xml")"
################ End of PowerTab Initialization Code ##########################

"@
        Write-Host ""
        Write-Host $Resources.setup_wizard_add_to_profile
        Write-Host $ProfileText

        ## Create new database or load existing database
        if ($SetupConfigurationPath -eq "IsolatedStorage") {
            $SetupDatabasePath = $SetupConfigurationPath
            if (Test-IsolatedStoragePath "PowerTab\TabExpansion.xml") {
                $Answer = $Host.UI.PromptForChoice($Resources.setup_wizard_upgrade_existing_database_caption, $Resources.setup_wizard_upgrade_existing_database_message, $YesNoChoices, 1)
            } else {
                $Answer = 0
            }
        } else {
            $SetupDatabasePath = Join-Path $SetupConfigurationPath "TabExpansion.xml"
            if (Test-Path $SetupDatabasePath) {
                $Answer = $Host.UI.PromptForChoice($Resources.setup_wizard_upgrade_existing_database_caption, $Resources.setup_wizard_upgrade_existing_database_message, $YesNoChoices, 1)
            } else {
                $Answer = 0
            }
        }
        if ($Answer) {
            Import-TabExpansionDataBase $SetupDatabasePath
        } else {
            New-TabExpansionDatabase
        }

        ## Update database
        Update-TabExpansionDataBase -Confirm

        ## Export changes
        Export-TabExpansionConfig
        Export-TabExpansionDatabase
        Write-Host ""
    } else {
        New-TabExpansionConfig
        CreatePowerTabConfig
        New-TabExpansionDatabase
    }
}

if ($PowerTabConfig.Enabled) {
    . "$PSScriptRoot\TabExpansion.ps1"
}

if ($PowerTabConfig.ShowBanner) {
    $CurVersion = (Get-Module -ListAvailable "PowerTab").Version
    Write-Host -ForegroundColor 'Yellow' "PowerTab version ${CurVersion} PowerShell TabExpansion Library"
    Write-Host -ForegroundColor 'Yellow' "Technology Preview"
    Write-Host -ForegroundColor 'Yellow' "PowerTab Enabled: $($PowerTabConfig.Enabled)"
}


## Exported functions, variables, etc.
$ExcludedFuctions = @("Initialize-TabExpansion")
$Functions = Get-Command "*-TabExpansion*" | Where-Object {$ExcludedFuctions -notcontains $_.Name}
#$Functions = Get-Command "*-*" | Where-Object {$ExcludedFuctions -notcontains $_.Name}
Export-ModuleMember -Function $Functions -Variable PowerTabConfig -Alias *

<#
TODOs
+ Console List: Fixed use of backspace and left arrow in some cases
+ Console List: Fixed exception from Write-Line
+ Console List: Fixed completing folder names with "/" causing problems (forces "\")
+ Fixed variable expansion looking at wrong scope
+ Fixed file system completion showing list for only one result
+ Fixed file system completion for registry keys (repeating paths)
+ Fixed completing members of variables in parentheses causing errors  ($test).<tab>
+ Verb expansion when declaring functions:  function re<TAB>
+ History uses '#' instead of 'h_':  #2<TAB>  or  #cd<TAB>
+ Quote values that have spaces
+ Variables sometimes need brackets:  ${foo.bar}
+ ScriptBlock members:  { 1+1 }.inv<TAB>
+ COM object names (PROGIDs)?
+ Fix footer of console list getting longer than the width of the list (leaves some characters that don't get cleaned up)
+ Fixed interop types not getting added to the database correctly
- Support variables in path:  $test = "C:"; $test\<TAB>
~ Expand items in a list:  Get-Command -CommandType Cm<TAB>,Fun<TAB>
- Assignment to strongly type variables:  $ErrorActionPreference = <TAB>
- Support accelerators:  [str<TAB>
$TypeAccelerators = [Type]::GetType("System.Management.Automation.TypeAccelerators")
$TypeAccelerators::Get.GetEnumerator() | Where-Object {$_.Key -like "$Matched*"} | ForEach-Object {"[$($_.Key)]"} | Sort-Object
- Alias and Variable replace:  ls^A  or  $test^A

- DateTime formats:  ^D<TAB>  or  2008/01/20^D<TAB>
- Paste clipboard:  ^V<TAB>
- Cut line:  Get-Foo -Bar something^X<TAB>  -->  
- Cut word:  Get-Foo -Bar something^Z<TAB>  -->  Get-Foo -Bar


- handle group start tokens ('{', '(', etc.)
~ Not detecting possitional parameters bound from pipeline
#>

<#
Token parsing examples.

FileSystem
$env:SystemDrive/pro<TAB>
Variable/Operator/Command

#>