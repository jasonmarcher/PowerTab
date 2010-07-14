# TabExpansionLib.ps1
#
# 


#########################
## Public functions
#########################

Function Invoke-TabActivityIndicator {
    [CmdletBinding()]
    param(
        [Switch]
        $Error
    )

    end {
        if ($PowerTabConfig.TabActivityIndicator) {
            if ("ConsoleHost","PowerShellPlus Host" -contains $Host.Name) {
                if ($Error) {
                    $MessageBuffer = ConvertTo-BufferCellArray ([String[]]@("[Err]")) Yellow Red
                } else {
                    $MessageBuffer = ConvertTo-BufferCellArray ([String[]]@("[Tab]")) Yellow Blue
                }
                if ($MessageHandle) {
                    $MessageHandle.Content = $MessageBuffer
                    $MessageHandle.Show()
                } else {
                    $script:MessageHandle = New-Buffer $Host.UI.RawUI.WindowPosition $MessageBuffer
                }
                if ($Error) {
                    Start-Sleep 1
                }
            } else {
                Write-Progress "PowerTab" $Resources.invoke_tabactivityindicator_prog_status
            }
        }
    }
}


Function Remove-TabActivityIndicator {
    [CmdletBinding()]
    param()

    end {
        if ($PowerTabConfig.TabActivityIndicator) {
            if ("ConsoleHost","PowerShellPlus Host" -contains $Host.Name) {
                if ($MessageHandle) {
                    $MessageHandle.Clear()
                    Remove-Variable -Name MessageHandle -Scope Script
                }
            } else {
                Write-Progress "PowerTab" $Resources.invoke_tabactivityindicator_prog_status -Completed
            }
        }
    }
}


Function Invoke-TabItemSelector {
    [CmdletBinding(DefaultParameterSetName = "Values")]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNull()]
        [String]
        $LastWord
        ,
        [ValidateSet("ConsoleList","Intellisense","Dynamic","Default")]
        [String]
        $SelectionHandler = "Default"
        ,
        [String]
        $ReturnWord
        ,
        [Parameter(ParameterSetName = "Values", ValueFromPipeline = $true)]
        [String[]]
        $Value
        ,
        [Parameter(ParameterSetName = "Objects")]
        [Object[]]
        $Object
        ,
        [Switch]
        $ForceList
    )

    begin {
        [String[]]$Values = @()
        [String[]]$Objects = @()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "Values") {
            $Values += $Value
        } else {
            $Objects += $Object
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }

    end {
        ## If dynamic, select an appropriate handler based on the current host
        if ($SelectionHandler -eq "Dynamic") {
            switch -exact ($Host.Name) {
                'ConsoleHost' {
                    $SelectionHandler = "ConsoleList"
                }
                'Windows PowerShell ISE Host' {
                    $SelectionHandler = "Default"
                }
                'PowerShellPlus Host' {
                    $SelectionHandler = "ConsoleList"
                }
                default {
                    $SelectionHandler = "Default"
                }
            }
        }

        ## Block certain handlers in hosts that don't support them
        ## Example, ConsoleList and Intellisense won't work in PowerShell ISE
        [String[]]$IncompatibleHandlers = @()
        switch -exact ($Host.Name) {
            'Windows PowerShell ISE Host' {
                $IncompatibleHandlers = "ConsoleList","Intellisense"
            }
            'PoshConsole' {
                $IncompatibleHandlers = "ConsoleList","Intellisense"
            }
        }
        if ($IncompatibleHandlers -contains $SelectionHandler) {$SelectionHandler = "Default"}

        ## List of selection handlers that can handle objects
        <# TODO: Upgrade ConsoleList
        $ObjectHandlers = @("ConsoleList")

        if (($ObjectHandlers -contains $SelectionHandler) -and ($PSCmdlet.ParameterSetName -eq "Values")) {
            $Objects = $Values | ForEach-Object {@{"Text"=$_;"Value"=$_}}
        } elseif (($ObjectHandlers -notcontains $SelectionHandler) -and ($PSCmdlet.ParameterSetName -eq "Objects")) {
            $Values = $Objects | ForEach-Object {$_.Value}
        }
        #>

        switch -exact ($SelectionHandler) {
            'ConsoleList' {$Values | Out-ConsoleList $LastWord $ReturnWord -ForceList:$ForceList}
            'Intellisense' {$Values | Invoke-Intellisense $LastWord}
            'Default' {$Values}
        }
    }
}

############

# .ExternalHelp TabExpansionLib-Help.xml
Function New-TabExpansionDatabase {
    [CmdletBinding()]
    param()

    end {
        $script:dsTabExpansionDatabase = New-Object System.Data.DataSet

        $dtCustom = New-Object System.Data.DataTable
        [Void]($dtCustom.Columns.Add('Filter', [String]))
        [Void]($dtCustom.Columns.Add('Text', [String]))
        [Void]($dtCustom.Columns.Add('Type', [String]))
        $dtCustom.TableName = 'Custom'
        $dsTabExpansionDatabase.Tables.Add($dtCustom)

        $dtTypes = New-Object System.Data.DataTable
        [Void]($dtTypes.Columns.Add('Name', [String]))
        [Void]($dtTypes.Columns.Add('DC', [String]))
        [Void]($dtTypes.Columns.Add('NS', [String]))
        $dtTypes.TableName = 'Types'
        $dsTabExpansionDatabase.Tables.Add($dtTypes)

        $dtWmi = New-Object System.Data.DataTable
        [Void]($dtWmi.Columns.Add('Name', [String]))
        [Void]($dtWmi.Columns.Add('Description', [String]))
        $dtWmi.TableName = 'Wmi'
        $dsTabExpansionDatabase.Tables.Add($dtWmi)

        . (Join-Path $PSScriptRoot "TabExpansionCustomLib.ps1")
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function New-TabExpansionConfig {
    [CmdletBinding()]
    param(
        [Alias("FullName","Path")]
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath = $PowerTabConfig.Setup.ConfigurationPath
    )

    end {
        $script:dsTabExpansionConfig = InternalNewTabExpansionConfig $LiteralPath
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Import-TabExpansionDataBase {
    [CmdletBinding()]
    param(
        [Alias("FullName","Path")]
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath = $PowerTabConfig.Setup.DatabasePath
    )

    end {
        $script:dsTabExpansionDatabase = InternalImportTabExpansionDataBase $LiteralPath
        Write-Verbose ($Resources.import_tabexpansiondatabase_ver_success -f $LiteralPath)
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Export-TabExpansionDatabase {
    [CmdletBinding()]
    param(
        [Alias("FullName","Path")]
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath = $PowerTabConfig.Setup.DatabasePath
    )

    end {
        try {
            if (-not $PowerTabConfig.Setup.DatabasePath) {
                $BlankDatabasePath = $true
                Write-Debug "Setting DatabasePath to $LiteralPath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = $LiteralPath
            }

            if ($LiteralPath -eq "IsolatedStorage") {
                New-IsolatedStorageDirectory "PowerTab"
                $IsoFile = Open-IsolatedStorageFile "PowerTab\TabExpansion.xml" -Writable
                $dsTabExpansionDatabase.WriteXml($IsoFile)
            } else {
                $dsTabExpansionDatabase.WriteXml($LiteralPath)
            }

            Write-Verbose ($Resources.export_tabexpansiondatabase_ver_success -f $LiteralPath)
        } finally {
            if ($BlankDatabasePath) {
                Write-Debug "Reverting DatabasePath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = ""
            }
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Import-TabExpansionConfig {
    [CmdletBinding()]
    param(
        [Alias("FullName","Path")]
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath = $PowerTabConfig.Setup.ConfigurationPath
    )

    end {
        $script:dsTabExpansionConfig = InternalImportTabExpansionConfig $LiteralPath
        Write-Verbose ($Resources.import_tabexpansionconfig_ver_success -f $LiteralPath)
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Export-TabExpansionConfig {
    [CmdletBinding()]
    param(
        [Alias("FullName","Path")]
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath = $PowerTabConfig.Setup.ConfigurationPath
    )

    end {
        try {
            if (-not $PowerTabConfig.Setup.ConfigurationPath) {
                $BlankConfigurationPath = $true
                Write-Debug "Setting ConfigurationPath to $LiteralPath"  ## TODO: localize
                $PowerTabConfig.Setup.ConfigurationPath = $LiteralPath
            }
            if (-not $PowerTabConfig.Setup.DatabasePath) {
                $BlankDatabasePath = $true
                if ($LiteralPath -eq "IsolatedStorage") {
                    $DatabasePath = $LiteralPath
                } else {
                    $DatabasePath = Join-Path (Split-Path $LiteralPath) TabExpansion.xml
                }
                Write-Debug "Setting DatabasePath to $DatabasePath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = $DatabasePath
            }

            if ($LiteralPath -eq "IsolatedStorage") {
                New-IsolatedStorageDirectory "PowerTab"
                $IsoFile = Open-IsolatedStorageFile "PowerTab\PowerTabConfig.xml" -Writable
                $dsTabExpansionConfig.Tables['Config'].WriteXml($IsoFile)
            } else {
                $dsTabExpansionConfig.Tables['Config'].WriteXml($LiteralPath)
            }

            Write-Verbose ($Resources.export_tabexpansionconfig_ver_success -f $LiteralPath)
        } finally {
            if ($BlankConfigurationPath) {
                Write-Debug "Reverting ConfigurationPath"  ## TODO: localize
                $PowerTabConfig.Setup.ConfigurationPath = ""
            }
            if ($BlankDatabasePath) {
                Write-Debug "Reverting DatabasePath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = ""
            }
            if ($IsoFile) {
                $IsoFile.Close()
            }
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Import-TabExpansionTheme {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param(
        [Parameter(ParameterSetName = "Name", Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
        ,
        [Alias("FullName","Path")]
        [Parameter(ParameterSetName = "LiteralPath", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath
    )

    end {
		if ($PSCmdlet.ParameterSetName -eq "Name") {
            Import-Csv (Join-Path $PSScriptRoot "ColorThemes\Theme${Name}.csv") | ForEach-Object {$PowerTabConfig.Colors."$($_.Name)" = $_.Color}
        } else {
            Import-Csv $LiteralPath | ForEach-Object {$PowerTabConfig.Colors."$($_.Name)" = $_.Color}
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Export-TabExpansionTheme {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param(
        [Parameter(ParameterSetName = "Name", Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
        ,
        [Alias("FullName","Path")]
        [Parameter(ParameterSetName = "LiteralPath", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath
    )

    process {
		if ($PSCmdlet.ParameterSetName -eq "Name") {
            $ExportPath = Join-Path $PSScriptRoot "ColorThemes\Theme${Name}.csv"
        } else {
            $ExportPath = $LiteralPath
        }
        $Colors = $PowerTabConfig.Colors | Get-Member -MemberType ScriptProperty |
            Select-Object @{Name='Name';Expression={$_.Name}},@{Name='Color';Expression={$PowerTabConfig.Colors."$($_.Name)"}} |
            Export-Csv $ExportPath -NoType

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

############

# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionDataBase {
	[CmdletBinding(SupportsShouldProcess = $true, SupportsTransactions = $false,
		ConfirmImpact = "Low", DefaultParameterSetName = "")]
	param(
        [Switch]
        $Force
    )

    end {
        if ($Force -or $PSCmdlet.ShouldProcess($Resources.update_tabexpansiondatabase_type_conf_description,
            $Resources.update_tabexpansiondatabase_type_conf_inquire, $Resources.update_tabexpansiondatabase_type_conf_caption)) {
            Update-TabExpansionType
        }
        if ($Force -or $PSCmdlet.ShouldProcess($Resources.update_tabexpansiondatabase_wmi_conf_description,
            $Resources.update_tabexpansiondatabase_wmi_conf_inquire, $Resources.update_tabexpansiondatabase_wmi_conf_caption)) {
            Update-TabExpansionWmi
        }
        if ($Force -or $PSCmdlet.ShouldProcess($Resources.update_tabexpansiondatabase_computer_conf_description,
            $Resources.update_tabexpansiondatabase_computer_conf_inquire, $Resources.update_tabexpansiondatabase_computer_conf_caption)) {
            Remove-TabExpansionComputer
            Add-TabExpansionComputer
        }
    }
}
Set-Alias udte Update-TabExpansionDataBase


# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionType {
	[CmdletBinding()]
    param()

    end {
        $dsTabExpansionDatabase.Tables['Types'].Clear()
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
        $Assemblies | ForEach-Object {
                $i++; $Assembly = $_
                [Int]$AssemblyProgress = ($i * 100) / $Assemblies.Length
                Write-Progress "Adding Assembly $($_.GetName().Name):" $AssemblyProgress -PercentComplete $AssemblyProgress
                trap{$Types = $Assembly.GetExportedTypes() | Where-Object {$_.IsPublic -eq $true}; continue}; $Types = $_.GetTypes() |
                    Where-Object {$_.IsPublic -eq $true}
                $Types | Foreach-Object {$j = 0} {
                        $j++
                        if (($j % 200) -eq 0) {
                            [Int]$TypeProgress = ($j * 100) / $Types.Length
                            Write-Progress "Adding types:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                        }
                        $dc = & {trap{continue;0}; $_.FullName.Split(".").Count - 1}
                        $ns = $_.NameSpace
                        [Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add($_.FullName, $dc, $ns)
                    }
            }
        Write-Progress "Adding types percent complete:" 100 -Id 1 -Completed

        # Add NameSpaces Without types
        $NL = $dsTabExpansionDatabase.Tables['Types'] | ForEach-Object {$i = 0} {
                $i++
                if (($i % 500) -eq 0) {
                    [Int]$TypeProgress = ($i * 100) / $dsTabExpansionDatabase.Tables['Types'].Rows.Count
                    Write-Progress "Adding namespaces:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                } 
                $Split = [Regex]::Split($_.Name,'\.')
                if ($Split.Length -gt 2) {
                    0..($Split.Length - 3) | ForEach-Object {$ofs='.'; "$($Split[0..($_)])"}
                }
            } | Sort-Object -Unique
        $nl | ForEach-Object {[Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add("Dummy", $_.Split('.').Count, $_)}
        Write-Progress "Adding NameSpaces percent complete:" 100 -Id 1 -Completed
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Add-TabExpansionType {
	[CmdletBinding()]
    param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Reflection.Assembly]
        $Assembly
    )

    process {
        $Assembly | ForEach-Object {
                $i++; $ass = $_
                trap{$Types = $ass.GetExportedTypes() | Where-Object {$_.IsPublic -eq $true}; continue}; $Types = $_.GetTypes() |
                    Where-Object {$_.IsPublic -eq $true}
                $Types | ForEach-Object {$j = 0} {
                        $j++;
                        if (($j % 200) -eq 0) {
                            [Int]$TypeProgress = ($j * 100) / $Types.Length
                            Write-Progress "Adding types:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                        } 
                        $dc = & {trap{continue;0}; $_.FullName.Split(".").Count - 1} 
                        $ns = $_.NameSpace 
                        [Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add($_.FullName, $dc, $ns)
                    }
            }
        Write-Progress "Adding types percent complete:" "100" -Id 1 -Completed

        # Add NameSpaces Without types
        $NL = $dsTabExpansionDatabase.Tables['Types'].select("ns = '$($ass.GetName().name)'") |
            ForEach-Object {$i = 0} {$i++
                if (($i % 500) -eq 0) {
                    [Int]$TypeProgress = ($i * 100) / $dsTabExpansionDatabase.Tables['Types'].Rows.Count
                    Write-Progress "Adding namespaces:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                }
                $Split = [Regex]::Split($_.Name,'\.')
                if ($Split.Length -gt 2) {
                    0..($Split.Length - 3) | ForEach-Object {$ofs='.'; "$($Split[0..($_)])"}
                }
            } | Sort-Object -Unique
        $nl | ForEach-Object {[Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add("Dummy",$_.Split('.').Count, $_)}
        Write-Progress "Adding NameSpaces percent complete:" 100 -Id 1 -Completed

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            Write-Progress "Adding NameSpaces percent complete:" 100 -Id 1 -Completed
            break
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionWmi {
	[CmdletBinding()]
    param()

    end {
        $dsTabExpansionDatabase.Tables['WMI'].Clear()

        # Set Enumeration Options
        $Options = New-Object System.Management.EnumerationOptions
        $Options.EnumerateDeep = $true
        $Options.UseAmendedQualifiers = $true

        $i = 0 ; Write-Progress "Adding WMI Classes" $i
        ([WmiClass]'').PSBase.GetSubclasses($Options) | ForEach-Object {
            $i++ ; if ($i % 10 -eq 0) {Write-Progress "Adding WMI Classes" $i}
            [Void]$dsTabExpansionDatabase.Tables['WMI'].Rows.Add($_.Name, ($_.PSbase.Qualifiers |
                Where-Object {$_.Name -eq 'Description'} | ForEach-Object {$_.Value}))
        }
        Write-Progress "Adding WMI Classes" $i -Completed
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Add-TabExpansionComputer {
	[CmdletBinding(SupportsShouldProcess = $false, SupportsTransactions = $false,
		ConfirmImpact = "None", DefaultParameterSetName = "")]
	param(
		[Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.DirectoryEntry]
        $OU
    )

    process {
        ## TODO: Localize progress messages
        $count = 0
        if ($OU) {
            $OU.PSBase.get_Children() | Select-Object @{e={$_.cn[0]};n='Name'} | ForEach-Object {
                $count++; if ($count % 5 -eq 0) {Write-Progress "Adding computer names" $count}
                Add-TabExpansion $_.Name $_.Name "Computer"
            }
        } else {
            net view | ForEach-Object {if ($_ -match '\\\\(.*?) ') {$Matches[1]}} | ForEach-Object {
                $count++; if ($count % 5 -eq 0) {Write-Progress "Adding computer names" $count}
                Add-TabExpansion $_ $_ "Computer"
            }
        }
        Write-Progress "Adding computer names" $count -Completed

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            Write-Progress "Adding computer names" $count -Completed
            break
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Remove-TabExpansionComputer {
	[CmdletBinding()]
    param()

    end {
        $dsTabExpansionDatabase.Tables['Custom'].Select("Type LIKE 'Computer'") | ForEach-Object {$_.Delete()}
    }
}

############

# .ExternalHelp TabExpansionLib-Help.xml
Function Get-TabExpansion {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String]
        $Filter = "*"
        ,
        [Parameter(Position = 1)]
        [String]
        $Type = "*"
    )

    ## TODO: Make Type a dynamic validateset?
    ## TODO: escape special characters?

    process {
        $Filter = $Filter -replace "\*","%"
        $Type = $Type -replace "\*","%"

        if ("Types","Wmi" -contains $Type){
            $dsTabExpansionDatabase.Tables[$Type].Select("Name LIKE '$Filter'")
        } else {
            $dsTabExpansionDatabase.Tables["Custom"].Select("Filter LIKE '$Filter' AND Type LIKE '$Type'")
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}
Set-Alias gte Get-TabExpansion


# .ExternalHelp TabExpansionLib-Help.xml
Function Add-TabExpansion {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text
        ,
        [Parameter(Position = 2)]
        [ValidateNotNull()]
        [String]
        $Type = 'Custom'
    )

    ## TODO: Add -PassThru support
    process {
        [Void]$dsTabExpansionDatabase.Tables['Custom'].Rows.Add($Filter, $Text, $Type)

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}
Set-Alias ate Add-TabExpansion


# .ExternalHelp TabExpansionLib-Help.xml
Function Remove-TabExpansion {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter
    )

    ## TODO: Add type
    process {
        $Filter = $Filter -replace "\*","%"

        $dsTabExpansionDatabase.Tables['Custom'].Select("Filter LIKE '$Filter'") | ForEach-Object {$_.Delete()}

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}
Set-Alias rte Remove-TabExpansion


# .ExternalHelp TabExpansionLib-Help.xml
Function Invoke-TabExpansionEditor {
	[CmdletBinding()]
    param()
    
    end {
        [System.Version]$CurVersion = (Get-Module -ListAvailable $PSCmdlet.MyInvocation.MyCommand.Module.Name).Version

        $Form = New-Object System.Windows.Forms.Form
        $Form.Size = New-Object System.Drawing.Size @(500,300)
        $Form.Text = "PowerTab $CurVersion PowerShell TabExpansion Library"

        $DataGrid = New-Object System.Windows.Forms.DataGrid
        $DataGrid.CaptionText = "Custom TabExpansion Database Editor"
        $DataGrid.AllowSorting = $true
        $DataGrid.DataSource = $dsTabExpansionDatabase.PSObject.BaseObject
        $DataGrid.Dock = [System.Windows.Forms.DockStyle]::Fill
        $Form.Controls.Add($DataGrid)
        $StatusBar = New-Object System.Windows.Forms.Statusbar
        $StatusBar.Text = " /\/\o\/\/ 2007 http://thePowerShellGuy.com"
        $Form.Controls.Add($StatusBar)

        ## Show the Form
        $Form.Add_Shown({$Form.Activate(); $DataGrid.Expand(0)})
        [Void]$Form.ShowDialog()
    }
}
Set-Alias itee Invoke-TabExpansionEditor

############

# .ExternalHelp TabExpansionLib-Help.xml
Function Register-TabExpansion {
	[CmdletBinding()]
    param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
        ,
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ScriptBlock]
        $Handler
        ,
        [ValidateSet("Command","CommandInfo","Parameter","ParameterName")]
        [String]
        $Type = "Command"
        ,
        [Switch]
        $Force
    )
    
    process {
        if ($Type -eq "Parameter") {
            if (-not $TabExpansionParameterRegistry[$Name] -or $Force) {
                $TabExpansionParameterRegistry[$Name] = $Handler
            }
        } elseif ($Type -eq "ParameterName") {
            if (-not $TabExpansionParameterNameRegistry[$Name] -or $Force) {
                $TabExpansionParameterNameRegistry[$Name] = $Handler
            }
        } elseif ($Type -eq "CommandInfo") {
            if (-not $TabExpansionCommandInfoRegistry[$Name] -or $Force) {
                $TabExpansionCommandInfoRegistry[$Name] = $Handler
            }
        } else {
            if (-not $TabExpansionCommandRegistry[$Name] -or $Force) {
                $TabExpansionCommandRegistry[$Name] = $Handler
            }
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}
Set-Alias rgte Register-TabExpansion



#########################
## Private functions
#########################

Function Initialize-PowerTab {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$ConfigurationPath = $PowerTabConfig.Setup.ConfigurationPath
    )

    ## Load Configuration
    if ($ConfigurationPath -and ((Test-Path $ConfigurationPath) -or ($ConfigurationPath -eq "IsolatedStorage"))) {
        $Config = InternalImportTabExpansionConfig (Convert-Path (Resolve-Path $ConfigurationPath))
    } else {
        ## TODO: Throw error or create new config?
        #$Config = InternalNewTabExpansionConfig $ConfigurationPath
    }

    ## Load Version
    [System.Version]$CurVersion = (Get-Module -ListAvailable $PSCmdlet.MyInvocation.MyCommand.Module.Name).Version
    $Version = $Config.Tables['Config'].Select("Name = 'Version'")[0].Value -as [System.Version]
    if ($Version -eq $null) {$Version = [System.Version]'0.99.0.0'}

    ## Load Database
    if ($Version -lt ([System.Version]'0.99.3.0')) {
        $DatabaseName = $Config.Tables['Config'].select("Name = 'DatabaseName'")[0].Value
        $DatabasePath = Join-Path ($Config.Tables['Config'].select("Name = 'DatabasePath'")[0].Value) $DatabaseName
    } else {
        $DatabasePath = $Config.Tables['Config'].select("Name = 'DatabasePath'")[0].Value
    }
    if(!(Split-Path $DatabasePath)) {
      $DatabasePath = Join-Path $PSScriptRoot $DataBasePath
    }
    
    $Database = InternalImportTabExpansionDataBase Convert-Path (Resolve-Path $DatabasePath)

    ## Upgrade if needed
    if ($Version -lt $CurVersion) {
        ## Upgrade config and database
        UpgradeTabExpansionDatabase ([Ref]$Config) ([Ref]$Database)
    } elseif ($Version -gt $CurVersion) {
        ## TODO: config is from a later version
    }

    ## Config and database are good
    $script:dsTabExpansionConfig = $Config
    $script:dsTabExpansionDatabase = $Database

    ## Create the user interface for the PowerTab settings
    CreatePowerTabConfig

    ## Set version
    $PowerTabConfig.Version = $CurVersion
}


Function UpgradeTabExpansionDatabase {
    [CmdletBinding()]
    param(
        [Ref]$Config
        ,
        [Ref]$Database
        ,
        [System.Version]$Version
    )

    <#
    For future releases, add new if conditions only if an upgrade path is needed due to changes
    in the database or config structure.  Or to add default values for new config settings.
    #>

    if ($Version -lt [System.Version]'0.99.3.0') {
        ## Upgrade versions from the first version of PowerTab
        Write-Host "Upgrading from version 0.99.X.0"
        UpgradePowerTab99 $Config $Database
        $Version = '0.99.3.0'
    }
}


Function UpgradePowerTab99 {
    [CmdletBinding()]
    param(
        [Ref]$Config
        ,
        [Ref]$Database
    )

    $Config.Value.Tables['Config'].Select("Name LIKE 'InstallPath' AND Category = 'Setup'") | ForEach-Object {$_.Delete()}
    if ($Database.Value.Tables['Config']) {
        $Database.Value.Tables.Remove('Config')
        trap{continue}
    }
    if ($Database.Value.Tables['Cache']) {
        $Database.Value.Tables.Remove('Cache')
        trap{continue}
    }
    $ConfigurationPath = $Config.Value.Tables['Config'].Select("Name = 'ConfigurationPath'")[0].Value
    $Config.Value.Tables['Config'].Select("Name = 'ConfigurationPath'")[0].Value = Join-Path $ConfigurationPath "PowerTabConfig.xml"
    $DatabasePath = $Config.Value.Tables['Config'].Select("Name = 'DatabasePath'")[0].Value
    $DatabaseName = $Config.Value.Tables['Config'].Select("Name = 'DatabaseName'")[0].Value
    $Config.Value.Tables['Config'].Select("Name = 'DatabasePath'")[0].Value = Join-Path $DatabasePath $DatabaseName
    $Config.Value.Tables['Config'].Select("Name = 'DatabaseName' AND Category = 'Setup'") | ForEach-Object {$_.Delete()}
}


Function InternalNewTabExpansionConfig {
    [CmdletBinding()]
    param(
        [String]$ConfigurationPath
    )
    
    if ($ConfigurationPath) {
        if ($ConfigurationPath -eq "IsolatedStorage") {
            $DatabasePath = $ConfigurationPath
        } else {
            $DatabasePath = Join-Path (Split-Path $ConfigurationPath) "TabExpansion.xml"
        }
    }

    $Config = New-Object System.Data.DataSet

    $dtConfig = New-Object System.Data.DataTable
    [Void]$dtConfig.Columns.Add('Category', [String])
    [Void]$dtConfig.Columns.Add('Name', [String])
    [Void]$dtConfig.Columns.Add('Value')
    [Void]$dtConfig.Columns.Add('Type')
    $dtConfig.TableName = 'Config'

    ## Add global configuration
    @{
        Version = (Get-Module -ListAvailable $PSCmdlet.MyInvocation.MyCommand.Module.Name).Version
        DefaultHandler = 'Dynamic'
        AlternateHandler = 'Dynamic'
        CustomUserFunction = 'Write-Warning'
        CustomCompletionChars = ']:)'
    }.GetEnumerator() | Foreach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'Global'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }
    @($dtConfig.Select("Name = 'Version'"))[0].Category = 'Version'

    ## Add color configuration
    $Items = `
        'BorderColor',
        'BorderBackColor',
        'BackColor',
        'TextColor',
        'SelectedBackColor',
        'SelectedTextColor',
        'BorderTextColor',
        'FilterColor'
    $DefaultColors = `
        'Blue',
        'DarkBlue',
        'DarkGray',
        'Yellow',
        'DarkRed',
        'Red',
        'Yellow',
        'DarkGray'
    0..($Items.GetUpperBound(0)) | Foreach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $items[$_]
            $row.Category = 'Colors'
            $row.Type = 'ConsoleColor'
            $row.Value = [ConsoleColor]($DefaultColors[$_])
            $dtConfig.Rows.Add($row)
        }

    ## Add shortcut configuration
    @{
        Alias   = '@'
        Partial = '%'
        Native  = '!'
        Invoke  = '&'
        Custom  = '^'
        CustomFunction  = '#'
    }.GetEnumerator() | Foreach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'ShortcutChars'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }

    ## Add setup configuration
    @{
        ConfigurationPath = $ConfigurationPath
        DatabasePath = $DatabasePath
    }.GetEnumerator() | Foreach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'Setup'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }

    $Options = @{
            Enabled = $True
            ShowBanner = $True
            TabActivityIndicator = $True
            AliasQuickExpand = $False
            FileSystemExpand = $True
            DoubleBorder = $True
            DoubleTabEnabled = $False
            DoubleTabLock = $False
            CloseListOnEmptyFilter = $True
            SpaceComplete = $True
            SpaceCompleteFileSystem = $True
            DotComplete = $True
            BackSlashComplete = $True
            CustomComplete = $True
            AutoExpandOnDot = $True
            AutoExpandOnBackSlash = $True
            CustomFunctionEnabled = $False
            IgnoreConfirmPreference = $False
            ShowAccessorMethods = $True
        }
    $Options.GetEnumerator() | Foreach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Bool'
            $row.Category = 'Global'
            $row.Value = [Int]($_.Value)
            $dtConfig.Rows.Add($row)
        }

    @{
        MinimumListItems   = '2'
        FastScrollItemcount = '10'
    }.GetEnumerator() | ForEach-Object {
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Int'
            $row.Category = 'Global'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }

    $Config.Tables.Add($dtConfig)
    $Config
}


Function InternalImportTabExpansionDataBase {
    [CmdletBinding()]
    param(
        [String]$LiteralPath
    )

    $Database = New-Object System.Data.DataSet
    if ($LiteralPath -eq "IsolatedStorage") {
        $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
        $IsoFile = New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream("PowerTab\TabExpansion.xml",
            [System.IO.FileMode]::Open, $UserIsoStorage)
        [Void]$Database.ReadXml($IsoFile)
    } else {
        [Void]$Database.ReadXml($LiteralPath)
    }
    $Database
}


Function InternalImportTabExpansionConfig {
    [CmdletBinding()]
    param(
        [String]$LiteralPath
    )

    $Config = New-Object System.Data.DataSet
    if ($LiteralPath -eq "IsolatedStorage") {
        $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
        $IsoFile = New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream("PowerTab\PowerTabConfig.xml",
            [System.IO.FileMode]::Open, $UserIsoStorage)
        [Void]$Config.ReadXml($IsoFile, 'InferSchema')
    } else {
        [Void]$Config.ReadXml($LiteralPath, 'InferSchema')
    }
    $Config
}


Function CreatePowerTabConfig {
    [CmdletBinding()]
    param()
    
    $script:PowerTabConfig = New-Object PSObject

    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Version -Value $dsTabExpansionConfig.Tables['Config'].Select("Name = 'Version'")[0].Value

    ## Add Enable ScriptProperty
    Add-Member -InputObject $PowerTabConfig -MemberType ScriptProperty -Name Enabled `
        -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(""Name = 'Enabled'"")[0]
            if (`$v.Type -eq 'Bool') {
                [Bool][Int]`$v.Value
            } else {
                [$($_.Type)](`$v.Value)
            }") `
        -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
            "trap {Write-Warning `$_; continue}
            [Int]`$val = [Bool]`$args[0]
            `$dsTabExpansionConfig.Tables['Config'].Select(""Name = 'Enabled'"")[0].Value = `$val
            if ([Bool]`$val) {
                . ""`$PSScriptRoot\TabExpansion.ps1""
            } else {
                Set-Content Function:\TabExpansion -Value `$OldTabExpansion
            }") `
        -Force

    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Colors -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.Colors -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Color Configuration}"} -Force

    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name ShortcutChars -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.ShortcutChars -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Shortcut Characters}"} -Force

    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Setup -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.Setup -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Setup Data}"} -Force

    ## Make global properties on config object
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Global'") | Where-Object {$_.Name -ne "Enabled"} | ForEach-Object {
            Add-Member -InputObject $PowerTabConfig -MemberType ScriptProperty -Name $_.Name `
                -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0]
                    if (`$v.Type -eq 'Bool') {
                        [Bool][Int]`$v.Value
                    } else {
                        [$($_.Type)](`$v.Value)
                    }") `
                -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "trap {Write-Warning `$_; continue}
                    `$val = [$($_.Type)]`$args[0]
                     if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                    `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value = `$val") `
                -Force
        }

    ## Make color properties on config object
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Colors'") | Foreach-Object {
            Add-Member -InputObject $PowerTabConfig.Colors -MemberType ScriptProperty -Name $_.Name `
                -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                 "`$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value") `
                -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "trap {Write-Warning `$_; continue}
                    `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value = [ConsoleColor]`$args[0]") `
                -Force
        }

    ## Make shortcut properties on config object
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'ShortcutChars'") | Foreach-Object {
            Add-Member -InputObject $PowerTabConfig.ShortcutChars -MemberType ScriptProperty -Name $_.Name `
                -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                 "`$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value") `
                -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "trap {Write-Warning `$_; continue}
                    `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value = `$args[0]") `
                -Force
        }

    ## Make Setup properties on Config Object
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Setup'") | Foreach-Object {
            Add-Member -InputObject $PowerTabConfig.Setup -MemberType ScriptProperty -Name $_.Name `
                -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0]
                    if (`$v.Type -eq 'Bool') {
                        [Bool][Int]`$v.Value
                    } else {
                        [$($_.Type)](`$v.Value)
                    }") `
                -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                    "trap {Write-Warning `$_; continue}
                    `$val = [$($_.Type)]`$args[0]
                     if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                    `$dsTabExpansionConfig.Tables['Config'].Select(""Name = '$($_.Name)'"")[0].Value = `$val") `
                -Force
        }
}
