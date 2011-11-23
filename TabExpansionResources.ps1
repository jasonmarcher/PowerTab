
Data Resources {
@{
    ## Default resources
    setup_wizard_caption = "Launch the setup wizard to create a PowerTab configuration file and database?"
    setup_wizard_message = "PowerTab can be setup manually without the setup wizard."
    setup_wizard_choice_profile_directory = "&Profile Directory"
    setup_wizard_choice_install_directory = "&Installation Directory"
    setup_wizard_choice_appdata_directory = "&Application Data Directory"
    setup_wizard_choice_isostorage_directory = "Isolated &Storage"
    setup_wizard_choice_other_directory = "&Other Directory"
    setup_wizard_config_location_caption = "Where should the PowerTab configuration file and database be saved?"
    setup_wizard_config_location_message = "Any existing PowerTab configuration will be overwritten."
    setup_wizard_other_directory_prompt = "Enter the directory path for storing the PowerTab configuration file and database"
    setup_wizard_err_path_not_valid = "The given path's format is not supported."
    setup_wizard_update_profile_caption = "Update current profile to automatically import PowerTab?"
    setup_wizard_update_profile_message = "To manually update the current profile or another profile, select 'No'."
    setup_wizard_add_to_profile = "Add the following text to the PowerShell profile to launch PowerTab with the saved configuration."
    setup_wizard_upgrade_existing_database_caption = "Upgrade existing tab completion database?"
    setup_wizard_upgrade_existing_database_message = "An existing tab completion database has been detected."
    update_tabexpansiondatabase_type_conf_caption = "Update .NET type list in tab completion database from currently loaded types?"
    update_tabexpansiondatabase_type_conf_inquire = "Loading .NET types."
    update_tabexpansiondatabase_type_conf_description = "Loading .NET types."
    update_tabexpansiondatabase_wmi_conf_caption = "Update WMI class list in tab completion database?"
    update_tabexpansiondatabase_wmi_conf_inquire = "Loading WMI classes."
    update_tabexpansiondatabase_wmi_conf_description = "Loading WMI classes."
    update_tabexpansiondatabase_wmi_activity = "Adding WMI Classes"
    update_tabexpansiondatabase_com_conf_caption = "Update COM class list in tab completion database?"
    update_tabexpansiondatabase_com_conf_inquire = "Loading COM classes."
    update_tabexpansiondatabase_com_conf_description = "Loading COM classes."
    update_tabexpansiondatabase_com_activity = "Adding COM Classes"
    update_tabexpansiondatabase_computer_conf_caption = "Update computer list in tab completion database from 'net view'?"
    update_tabexpansiondatabase_computer_conf_inquire = "Loading computer names."
    update_tabexpansiondatabase_computer_conf_description = "Loading computer names."
    update_tabexpansiondatabase_computer_activity = "Adding computer names"
    import_tabexpansiondatabase_ver_success = "TabExpansion database imported from '{0}'"
    export_tabexpansiondatabase_ver_success = "TabExpansion database exported to '{0}'"
    import_tabexpansionconfig_ver_success = "Configuration imported from '{0}'"
    export_tabexpansionconfig_ver_success = "Configuration exported to '{0}'"
    invoke_tabactivityindicator_prog_status = "PowerTab is retrieving or displaying available tab expansion options."
    global_choice_yes = "&Yes"
    global_choice_no = "&No"
}
}

$ResourceFiles = @(
        @{"FileName"="Resources";"Variable"="Resources";"Cultures"=@("en-US")}
    )


############

Function Update-Resource {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $FileName
        ,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $Variable
        ,
        [Parameter(Position = 2, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Globalization.CultureInfo[]]
        $Cultures
    )

    process {
        [System.Globalization.CultureInfo]$ControlCulture = "en"
        $ResourceCollection = @{}
        $BaseResources = (Get-Variable $Variable).Value
        $BaseKeys = $BaseResources.Keys.GetEnumerator() | Sort-Object

        ## Update control resources
        [String[]]$ModifiedKeys = @()
        [Bool]$Modified = $false
        $ControlResources = Import-Resources $ControlCulture -FileName $FileName
        $ControlKeys = $ControlResources.Keys.GetEnumerator() | Sort-Object
        Compare-Object $BaseKeys $ControlKeys -IncludeEqual | ForEach-Object {
            $Key = $_.InputObject
            switch -exact ($_.SideIndicator) {
                '<=' {
                    ## This key is new since last update, add to control
                    $ControlResources[$Key] = $BaseResources[$Key]
                    $Modified = $true
                    Write-Host "A new key has been identified: $Key"  # TODO: Improve message
                }
                '=>' {
                    ## This key was removed since last update, remove from control
                    $ControlResources.Remove($Key)
                    $Modified = $true
                    Write-Host "A key has been removed: $Key"  # TODO: Improve message
                }
                '==' {
                    ## Key still here, check if value has changed
                    if ($BaseResources[$Key] -cne $ControlResources[$Key]) {
                        ## Value changed, add key to changed list and update control
                        $ModifiedKeys += $Key
                        $ControlResources[$Key] = $BaseResources[$Key]
                        $Modified = $true
                        Write-Host "The value for key '$Key' has been modified."  # TODO: Improve message
                    }
                }
            }
        }
        if ($Modified) {
            Export-Resources $ControlCulture $ControlResources -FileName $FileName
        }

        ## Update localized languages
        foreach ($Culture in $Cultures) {
            $Modified = $false
            $CultureResources = Import-Resources $Culture -FileName $FileName
            $CultureKeys = $CultureResources.Keys.GetEnumerator() | Sort-Object
            Compare-Object $BaseKeys $CultureKeys -IncludeEqual | ForEach-Object {
                $Key = $_.InputObject
                switch -exact ($_.SideIndicator) {
                    '<=' {
                        ## This key is new since last update, add to culture
                        $CultureResources[$Key] = $BaseResources[$Key]
                        $Modified = $true
                        Write-Host "Adding key '$Key' to '$($Culture.Name)'"  # TODO: Improve message
                        Write-Verbose "  Value: '$($BaseResources[$Key])'"
                    }
                    '=>' {
                        ## This key was removed since last update, remove from culture
                        $CultureResources.Remove($Key)
                        $Modified = $true
                        Write-Host "Removing key '$Key' from '$($Culture.Name)'"  # TODO: Improve message
                    }
                    '==' {
                        ## Key still here, check if value has changed
                        if ($ModifiedKeys -contains $Key) {
                            ## Value changed, add key to changed list and update culture
                            Write-Host "Key '$Key' has changed, updating value in '$($Culture.Name)' from base resources"  # TODO: Improve message
                            Write-Verbose "  Old value: '$($CultureResources[$Key])'"
                            Write-Verbose "  New value: '$($BaseResources[$Key])'"
                            $CultureResources[$Key] = $BaseResources[$Key]
                            $Modified = $true
                        }
                    }
                }
            }

            ## Update culture resources
            if ($Modified) {
                Export-Resources $Culture $CultureResources -FileName $FileName
            }
        }
    }
}


Function Import-Resources {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Globalization.CultureInfo]
        $Culture
        ,
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName = "Resources"
    )

    process {
        if (Test-Path "$PSScriptRoot\$($Culture.Name)\$FileName.psd1") {
            Import-LocalizedData -BindingVariable "TempResources" -FileName $FileName -UICulture $Culture -ErrorAction SilentlyContinue
            $TempResources
        } else {
            @{}
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}


Function Export-Resources {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Globalization.CultureInfo]
        $Culture
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        $Resources
        ,
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName = "Resources"
    )

    process {
        $Contents = "`@{`n    ## $($Culture.Name)`r`n"
        foreach ($Key in ($Resources.Keys | Sort-Object)) {
            $Contents += "    {0} = `"{1}`"`r`n" -f $Key,$Resources[$Key]
        }
        $Contents += "}"
        
        Set-Content -Path "$PSScriptRoot\$($Culture.Name)\$FileName.psd1" -Value $Contents

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

<#
$mod = (get-module -All PowerTab)[0]
& $mod Update-Resources -verbose
#>


$ResourceFiles | ForEach-Object {Update-Resource @_}