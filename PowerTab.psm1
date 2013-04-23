param()

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

if (Test-Path Function:TabExpansion) {
    $OldTabExpansion = Get-Content Function:TabExpansion
} else {
    ## This is a temporary compatibility change for PowerShell v3.
    $OldTabExpansion = $null
}
$Module = $MyInvocation.MyCommand.ScriptBlock.Module 
$Module.OnRemove = {
    if ((Get-Command TabExpansion).Module.Name -eq "PowerTab") {
        ## Only reset TabExpansion() if PowerTab's override is currently in use
        $Function:TabExpansion = $OldTabExpansion
    }
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

$ConfigFileName = "PowerTabConfig.xml"

$PSv3HasRun = if ($PSVersionTable.PSVersion -eq "3.0") {$false} else {$true}


#########################
## Public properties
#########################

$PowerTabConfig = New-Object System.Management.Automation.PSObject

New-Variable PowerTabLog -Value (
    New-Object PSObject -Property @{
        Error = New-Object System.Collections.ArrayList
        Debug = New-Object System.Collections.ArrayList
        DebugEnabled = $false
        Trace = New-Object System.Collections.ArrayList
        TraceEnabled = $false
    }
)


#########################
## Functions
#########################

Import-Module (Join-Path $PSScriptRoot "Lerch.PowerShell.dll")
. (Join-Path $PSScriptRoot "TabExpansionResources.ps1")
Import-LocalizedData -BindingVariable Resources -FileName Resources -ErrorAction SilentlyContinue
. (Join-Path $PSScriptRoot "TabExpansionCore.ps1")
. (Join-Path $PSScriptRoot "TabExpansionLib.ps1")
. (Join-Path $PSScriptRoot "TabExpansionUtil.ps1")
. (Join-Path $PSScriptRoot "TabExpansionHandlers.ps1")
. (Join-Path $PSScriptRoot "ConsoleLib.ps1")
. (Join-Path $PSScriptRoot "Readline.ps1")
. (Join-Path $PSScriptRoot "Handlers\PSClientManager.ps1")
. (Join-Path $PSScriptRoot "Handlers\Robocopy.ps1")
. (Join-Path $PSScriptRoot "Handlers\Utilities.ps1")


#########################
## Initialization code
#########################

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
    } elseif ($PrivateData = (Parse-Manifest).PrivateData) {
        $script:ConfigurationPathParam = $PrivateData
    } elseif (Test-Path (Join-Path (Split-Path $Profile) $ConfigFileName)) {
        $script:ConfigurationPathParam = (Join-Path (Split-Path $Profile) $ConfigFileName)
    } elseif (Test-Path (Join-Path $PSScriptRoot $ConfigFileName)) {
        $script:ConfigurationPathParam = (Join-Path $PSScriptRoot $ConfigFileName)
    }
} @args

if ($ConfigurationPathParam) {
    if ((Test-Path $ConfigurationPathParam) -or (
            ($ConfigurationPathParam -eq "IsolatedStorage") -and (Test-IsolatedStoragePath "PowerTab\$ConfigFileName"))) {
        Initialize-PowerTab $ConfigurationPathParam
    } else {
        ## Config specified, but does not exist
        Write-Warning "Configuration File does not exist: '$ConfigurationPathParam'"  ## TODO: localize

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
            0 {$ExecutionContext.SessionState.Path.ParseParent($Profile, $null)}
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
            New-TabExpansionConfig (Join-Path $SetupConfigurationPath $ConfigFileName)
        }
        CreatePowerTabConfig

        ## Profile text
        ## TODO: Localize this text?
        $ProfileText = @"

<############### Start of PowerTab Initialization Code ########################
    Added to profile by PowerTab setup for loading of custom tab expansion.
    Import other modules after this, they may contain PowerTab integration.
#>

Import-Module "PowerTab" -ArgumentList "$(Join-Path $SetupConfigurationPath $ConfigFileName)"
################ End of PowerTab Initialization Code ##########################

"@
        if (-not (Select-String "Start of PowerTab Initialization Code" $PROFILE)) {
            $Answer = $Host.UI.PromptForChoice($Resources.setup_wizard_update_profile_caption, $Resources.setup_wizard_update_profile_message, $YesNoChoices, 1)

            if ($Answer) {
                $Text = $ProfileText + "`r`n" + (Get-Content $PROFILE -Delimiter `0 -ErrorAction SilentlyContinue)
                $Encoding = Get-FileEncoding $PROFILE
                Set-Content $PROFILE $Text -Encoding $Encoding
            } else {
                Write-Host ""
                Write-Host $Resources.setup_wizard_add_to_profile
                Write-Host $ProfileText
            }
        }
        ## TODO: Check if import of PowerTab code needs to be updated?

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
    $CurVersion = (Parse-Manifest).ModuleVersion
    ## TODO:  Localize?
    Write-Host -ForegroundColor 'Yellow' "PowerTab version ${CurVersion} PowerShell TabExpansion Library"
    Write-Host -ForegroundColor 'Yellow' "Host: $($Host.Name)"
    Write-Host -ForegroundColor 'Yellow' "PowerTab Enabled: $($PowerTabConfig.Enabled)"
}


## Exported functions, variables, etc.
$ExcludedFuctions = @("Initialize-TabExpansion")
$Functions = Get-Command "*-TabExpansion*","New-TabItem" | Where-Object {$ExcludedFuctions -notcontains $_.Name}
Export-ModuleMember -Function $Functions -Variable PowerTabConfig, PowerTabLog -Alias *
