using namespace System.Management.Automation

# TabExpansionLib.ps1
#
# 

## Reason: Script analyzer doesn't catch all variable usages
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

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
                    $MessageBuffer = ConvertTo-BufferCellArray ([String[]]"[Err]") Yellow Red
                } else {
                    $MessageBuffer = ConvertTo-BufferCellArray ([String[]]"[Tab]") Yellow Blue
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        if ("ConsoleHost","PowerShellPlus Host" -contains $Host.Name) {
            if ($MessageHandle) {
                $MessageHandle.Clear()
                Remove-Variable -Name MessageHandle -Scope Script
            }
        } else {
            if ($PowerTabConfig.TabActivityIndicator) {
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
        [ValidateSet("ConsoleList","CommonPrefix","Dynamic","Default","ObjectDefault")]
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
        [Parameter(ParameterSetName = "Objects", ValueFromPipeline = $true)]
        [Object[]]
        $Object
        ,
        [Switch]
        $ForceList
    )

    begin {
        Write-Trace "Invoking Tab Item Selector."
        $SelectionReason = "it is the user's choice"

        if (-not $PSBoundParameters.ContainsKey("ReturnWord")) {$ReturnWord = $LastWord}

        [String[]]$Values = @()
        [Object[]]$Objects = @()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "Values") {
            $Values += $Value
        } else {
            $Objects += $Object
        }

        trap [PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }

    end {
        Write-Debug "Invoke-TabItemSelector parameter set: $($PSCmdlet.ParameterSetName)"

        if (($Objects.Count -eq 0) -and ($Values.Count -eq 0)) {
            if ($ReturnWord) {
                $ReturnWord
            }
            return
        }

        ## If dynamic, select an appropriate handler based on the current host
        if ($SelectionHandler -eq "Dynamic") {
            $SelectionReason = "it is the perferred handler for the current host"
            switch -exact ($Host.Name) {
                'ConsoleHost' {  ## PowerShell.exe
                    $SelectionHandler = "ConsoleList"
                    break
                }
                'PoshConsole' {
                    $SelectionHandler = "Default"
                    break
                }
                'PowerShellPlus Host' {
                    $SelectionHandler = "ConsoleList"
                    break
                }
                'Windows PowerShell ISE Host' {
                    $SelectionHandler = "ObjectDefault"
                    break
                }
                default {
                    $SelectionHandler = "Default"
                    break
                }
            }
        }

        ## Block certain handlers in hosts that don't support them
        ## Example, ConsoleList won't work in PowerShell ISE
        [String[]]$IncompatibleHandlers = @()
        switch -exact ($Host.Name) {
            'ConsoleHost' {  ## PowerShell.exe
                break
            }
            'PoshConsole' {
                $IncompatibleHandlers += "ConsoleList"
                break
            }
            'PowerGUIHost' {
                $IncompatibleHandlers += "ConsoleList"
                break
            }
            'PowerGUIScriptEditorHost' {
                $IncompatibleHandlers += "ConsoleList"
                break
            }
            'PowerShellPlus Host' {
                break
            }
            'Windows PowerShell ISE Host' {
                $IncompatibleHandlers += "ConsoleList"
                break
            }
        }
        if ($IncompatibleHandlers -contains $SelectionHandler) {
            $SelectionReason = "the chosen handler is not compatible with the current host"
            $SelectionHandler = "Default"
        }

        ## List of selection handlers that can handle objects
        $ObjectHandlers = @("ConsoleList","CommonPrefix","ObjectDefault")
        if (($ObjectHandlers -contains $SelectionHandler) -and ($PSCmdlet.ParameterSetName -eq "Values")) {
            $Objects = foreach ($Item in $Values) {New-TabItem -Value $Item -Text $Item}
        } elseif (($ObjectHandlers -notcontains $SelectionHandler) -and ($PSCmdlet.ParameterSetName -eq "Objects")) {
            $Values = foreach ($Item in $Objects) {$Item.CompletionText}
        }

        Write-Trace "Decided to invoke $SelectionHandler, because $SelectionReason."

        switch -exact ($SelectionHandler) {
            'ConsoleList' {$Objects | Out-ConsoleList $LastWord $ReturnWord -ForceList:$ForceList}
            'CommonPrefix' {$Objects | Show-CommonPrefix $LastWord}
            'ObjectDefault' {$Objects}
            'Default' {$Values}
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function New-TabItem {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Value
        ,
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text = $Value
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Type = "Unknown"
        ,
        [Parameter()]
        [CompletionResultType]
        $ResultType = "Text"
        ,
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ToolTip = $Text
    )

    process {
        New-Object CompletionResult $Value, $Text, $ResultType, $ToolTip
    }
}

############

# .ExternalHelp TabExpansionLib-Help.xml
Function New-TabExpansionDatabase {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        $script:dsTabExpansionDatabase = New-Object System.Data.DataSet

        $dtCom = New-Object System.Data.DataTable
        [Void]($dtCom.Columns.Add('Name', [String]))
        [Void]($dtCom.Columns.Add('Description', [String]))
        $dtCom.TableName = 'COM'
        $dsTabExpansionDatabase.Tables.Add($dtCom)

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
        $dtWmi.TableName = 'WMI'
        $dsTabExpansionDatabase.Tables.Add($dtWmi)

        . (Join-Path $PSScriptRoot "TabExpansionCustomLib.ps1")
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function New-TabExpansionConfig {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
                Write-Verbose "Setting DatabasePath to $LiteralPath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = $LiteralPath
            }

            if ($LiteralPath -eq "IsolatedStorage") {
                New-IsolatedStorageDirectory "PowerTab"
                $IsoFile = Open-IsolatedStorageFile "PowerTab/TabExpansion.xml" -Writable
                $dsTabExpansionDatabase.WriteXml($IsoFile)
            } else {
                if (-not (Test-Path (Split-Path $LiteralPath))) {
                    New-Item (Split-Path $LiteralPath) -ItemType Directory > $null
                }
                $dsTabExpansionDatabase.WriteXml($LiteralPath)
            }

            Write-Verbose ($Resources.export_tabexpansiondatabase_ver_success -f $LiteralPath)
        } finally {
            if ($BlankDatabasePath) {
                Write-Verbose "Reverting DatabasePath"  ## TODO: localize
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
        $Config = InternalImportTabExpansionConfig $LiteralPath

        ## Load Version
        [System.Version]$CurVersion = (Parse-Manifest).ModuleVersion
        $Version = $Config.Tables['Config'].Select("Name = 'Version'")[0].Value -as [System.Version]

        ## Upgrade if needed
        $UpgradeOccurred = $false
        if ($Version -lt $CurVersion) {
            ## Upgrade config
            $UpgradeOccurred = UpgradeTabExpansionDatabase ([Ref]$Config) ([Ref](New-Object System.Data.DataSet)) $Version
        } elseif ($Version -gt $CurVersion) {
            ## TODO: config is from a later version
        }

        $script:dsTabExpansionConfig = $Config

        ## Set version
        $PowerTabConfig.Version = $CurVersion

        ## Export the newly upgraded config
        if ($UpgradeOccurred) {
            Export-TabExpansionConfig
        }

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
                Write-Verbose "Setting ConfigurationPath to $LiteralPath"  ## TODO: localize
                $PowerTabConfig.Setup.ConfigurationPath = $LiteralPath
            }
            if (-not $PowerTabConfig.Setup.DatabasePath) {
                $BlankDatabasePath = $true
                if ($LiteralPath -eq "IsolatedStorage") {
                    $DatabasePath = $LiteralPath
                } else {
                    $DatabasePath = Join-Path (Split-Path $LiteralPath) TabExpansion.xml
                }
                Write-Verbose "Setting DatabasePath to $DatabasePath"  ## TODO: localize
                $PowerTabConfig.Setup.DatabasePath = $DatabasePath
            }

            if ($LiteralPath -eq "IsolatedStorage") {
                New-IsolatedStorageDirectory "PowerTab"
                $IsoFile = Open-IsolatedStorageFile "PowerTab/PowerTabConfig.xml" -Writable
                $dsTabExpansionConfig.Tables['Config'].WriteXml($IsoFile)
            } else {
                if (-not (Test-Path (Split-Path $LiteralPath))) {
                    New-Item (Split-Path $LiteralPath) -ItemType Directory > $null
                }
                $dsTabExpansionConfig.Tables['Config'].WriteXml($LiteralPath)
            }

            Write-Verbose ($Resources.export_tabexpansionconfig_ver_success -f $LiteralPath)
        } finally {
            if ($BlankConfigurationPath) {
                Write-Verbose "Reverting ConfigurationPath"  ## TODO: localize
                $PowerTabConfig.Setup.ConfigurationPath = ""
            }
            if ($BlankDatabasePath) {
                Write-Verbose "Reverting DatabasePath"  ## TODO: localize
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
            Import-Csv (Join-Path $PSScriptRoot "ColorThemes/Theme${Name}.csv") | . {process{$PowerTabConfig.ConsoleList.Colors."$($_.Name)" = $_.Color}}
        } else {
            Import-Csv $LiteralPath | . {process{$PowerTabConfig.ConsoleList.Colors."$($_.Name)" = $_.Color}}
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
            $ExportPath = Join-Path $PSScriptRoot "ColorThemes/Theme${Name}.csv"
        } else {
            $ExportPath = $LiteralPath
        }
        $Colors = $PowerTabConfig.ConsoleList.Colors | Get-Member -MemberType ScriptProperty |
            Select-Object @{Name='Name';Expression={$_.Name}},@{Name='Color';Expression={$PowerTabConfig.ConsoleList.Colors."$($_.Name)"}} |
            Export-Csv $ExportPath -NoType

        trap [PipelineStoppedException] {
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
        if ($Force -or $PSCmdlet.ShouldProcess($Resources.update_tabexpansiondatabase_com_conf_description,
            $Resources.update_tabexpansiondatabase_com_conf_inquire, $Resources.update_tabexpansiondatabase_com_conf_caption)) {
            Update-TabExpansionCom
        }
        if ($Force -or $PSCmdlet.ShouldProcess($Resources.update_tabexpansiondatabase_computer_conf_description,
            $Resources.update_tabexpansiondatabase_computer_conf_inquire, $Resources.update_tabexpansiondatabase_computer_conf_caption)) {
            Remove-TabExpansionComputer
            Add-TabExpansionComputer -NetView
        }
    }
}
Set-Alias udte Update-TabExpansionDataBase


# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionType {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        $dsTabExpansionDatabase.Tables['Types'].Clear()
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
        $Assemblies | . {process{
            $i++; $Assembly = $_
            [Int]$AssemblyProgress = ($i * 100) / $Assemblies.Length
            Write-Progress "Adding Assembly $($_.GetName().Name):" $AssemblyProgress -PercentComplete $AssemblyProgress
            trap{$Types = $Assembly.GetExportedTypes() | Where-Object {$_.IsPublic -eq $true}; continue}; $Types = $_.GetTypes() |
                Where-Object {$_.IsPublic -eq $true}
            $Types | . {begin{$j = 0} process{
                    $j++
                    if (($j % 200) -eq 0) {
                        [Int]$TypeProgress = ($j * 100) / $Types.Length
                        Write-Progress "Adding types:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                    }
                    $dc = & {trap{continue;0}; $_.FullName.Split(".").Count - 1}
                    $ns = $_.NameSpace
                    [Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add($_.FullName, $dc, $ns)
                }}
        }}
        Write-Progress "Adding types percent complete:" 100 -Id 1 -Completed

        # Add NameSpaces Without types
        $NL = $dsTabExpansionDatabase.Tables['Types'] | . {begin{$i = 0} process{
                $i++
                if (($i % 500) -eq 0) {
                    [Int]$TypeProgress = ($i * 100) / $dsTabExpansionDatabase.Tables['Types'].Rows.Count
                    Write-Progress "Adding namespaces:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                } 
                $Split = [Regex]::Split($_.Name,'\.')
                if ($Split.Length -gt 2) {
                    0..($Split.Length - 3) | . {process{$ofs='.'; "$($Split[0..($_)])"}}
                }
            }} | Sort-Object -Unique
        $nl | . {process{[Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add("Dummy", $_.Split('.').Count, $_)}}
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
        $Assembly | . {process{
            $i++; $ass = $_
            trap{$Types = $ass.GetExportedTypes() | Where-Object {$_.IsPublic -eq $true}; continue}; $Types = $_.GetTypes() |
                Where-Object {$_.IsPublic -eq $true}
            $Types | . {begin{$j = 0} process{
                    $j++;
                    if (($j % 200) -eq 0) {
                        [Int]$TypeProgress = ($j * 100) / $Types.Length
                        Write-Progress "Adding types:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                    } 
                    $dc = & {trap{continue;0}; $_.FullName.Split(".").Count - 1} 
                    $ns = $_.NameSpace 
                    [Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add($_.FullName, $dc, $ns)
                }}
        }}
        Write-Progress "Adding types percent complete:" "100" -Id 1 -Completed

        # Add NameSpaces Without types
        $NL = $dsTabExpansionDatabase.Tables['Types'].select("ns = '$($ass.GetName().name)'") |
            . {begin{$i = 0} process{$i++
                if (($i % 500) -eq 0) {
                    [Int]$TypeProgress = ($i * 100) / $dsTabExpansionDatabase.Tables['Types'].Rows.Count
                    Write-Progress "Adding namespaces:" $TypeProgress -PercentComplete $TypeProgress -Id 1
                }
                $Split = [Regex]::Split($_.Name,'\.')
                if ($Split.Length -gt 2) {
                    0..($Split.Length - 3) | . {process{$ofs='.'; "$($Split[0..($_)])"}}
                }
            }} | Sort-Object -Unique
        $nl | . {process{[Void]$dsTabExpansionDatabase.Tables['Types'].Rows.Add("Dummy",$_.Split('.').Count, $_)}}
        Write-Progress "Adding NameSpaces percent complete:" 100 -Id 1 -Completed

        trap [PipelineStoppedException] {
            ## Pipeline was stopped
            Write-Progress "Adding NameSpaces percent complete:" 100 -Id 1 -Completed
            break
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Find-TabExpansionType {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [String]
        $Name
    )

    process {
        ## TODO: Find way to differentiate namespaces from types
        $Dots = $Name.Split(".").Count - 1
        $res = @()

        $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like '$Name*' and DC = $($Dots + 1)") |
            Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -ResultType Namespace
        $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like 'System.$Name*' and DC = $($Dots + 2)") |
            Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -ResultType Namespace
        if ($Dots -gt 0) {
            $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like '$Name*' and DC = $Dots") |
                Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -ResultType Type
            $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like 'System.$Name*' and DC = $($Dots + 1)") |
                Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -ResultType Type
        }
        $res | Where-Object {$_}
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionWmi {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        $dsTabExpansionDatabase.Tables['WMI'].Clear()

        # Set Enumeration Options
        $Options = New-Object System.Management.EnumerationOptions
        $Options.EnumerateDeep = $true
        $Options.UseAmendedQualifiers = $true

        $i = 0 ; Write-Progress $Resources.update_tabexpansiondatabase_wmi_activity $i
        foreach ($Class in (([WmiClass]'').PSBase.GetSubclasses($Options))) {
            $i++ ; if ($i % 10 -eq 0) {Write-Progress $Resources.update_tabexpansiondatabase_wmi_activity $i}
            $Description = try { $Class.GetQualifierValue('Description') } catch {""}
            [Void]$dsTabExpansionDatabase.Tables['WMI'].Rows.Add($Class.Name, $Description)
        }
        Write-Progress $Resources.update_tabexpansiondatabase_wmi_activity $i -Completed
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Update-TabExpansionCom {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        $dsTabExpansionDatabase.Tables['COM'].Clear()

        $i = 0 ; Write-Progress $Resources.update_tabexpansiondatabase_com_activity $i
        foreach ($Class in (Get-CimInstance -ClassName "Win32_ClassicCOMClassSetting" -Filter "VersionIndependentProgId LIKE '%'" |
                Sort-Object VersionIndependentProgId)) {
            $i++ ; if ($i % 10 -eq 0) {Write-Progress $Resources.update_tabexpansiondatabase_com_activity $i}
            [Void]$dsTabExpansionDatabase.Tables['COM'].Rows.Add($Class.VersionIndependentProgId, $Class.Description)
        }
        Write-Progress $Resources.update_tabexpansiondatabase_com_activity $i -Completed
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Add-TabExpansionComputer {
    [CmdletBinding(SupportsShouldProcess = $false, SupportsTransactions = $false,
        ConfirmImpact = "None", DefaultParameterSetName = "Name")]
    param(
        [Alias("Name")]
        [Parameter(ParameterSetName = "Name", Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName
        ,
        [Parameter(ParameterSetName = "OU", Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.DirectoryEntry]
        $OU
        ,
        [Parameter(ParameterSetName = "NetView")]
        [Switch]
        $NetView
    )

    process {
        $count = 0
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            Add-TabExpansion $ComputerName $ComputerName "Computer"
        } elseif ($PSCmdlet.ParameterSetName -eq "OU") {
            foreach ($Computer in ($OU.PSBase.get_Children() | Select-Object @{Name='Name';Expression={$_.cn[0]}})) {
                $count++; if ($count % 5 -eq 0) {Write-Progress $Resources.update_tabexpansiondatabase_computer_activity $count}
                Add-TabExpansion $Computer.Name $Computer.Name Computer
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "NetView") {
            foreach ($Line in (net view)) {
                if ($Line -match '\\\\(.*?) ') {
                    $Computer = $Matches[1]
                    $count++; if ($count % 5 -eq 0) {Write-Progress $Resources.update_tabexpansiondatabase_computer_activity $count}
                    Add-TabExpansion $Computer $Computer Computer
                }
            }
        }
        if ($PSCmdlet.ParameterSetName -ne "Name") {
            Write-Progress $Resources.update_tabexpansiondatabase_computer_activity $count -Completed
        }

        trap [PipelineStoppedException] {
            ## Pipeline was stopped
            if ($PSCmdlet.ParameterSetName -ne "Name") {
                Write-Progress $Resources.update_tabexpansiondatabase_computer_activity $count -Completed
            }
            break
        }
    }
}


# .ExternalHelp TabExpansionLib-Help.xml
Function Remove-TabExpansionComputer {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    end {
        foreach ($Computer in $dsTabExpansionDatabase.Tables['Custom'].Select("Type LIKE 'Computer'")) {
            $Computer.Delete()
        }
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
        ## Split filter on internal wildcards as DataTables do not support them
        $Filters = @($Filter -split '(?<=.)[\*%](?=.)')
        if ($Filters.Count -gt 1) {
            $Filters[0] = $Filters[0] + "*"  ## First item
            $Filters[-1] = "*" + $Filters[-1]  ## Last item

            if ($Filters.Count -gt 2) {
                foreach ($Index in 1..($Filters.Count - 2)) {
                    $Filters[$Index] = "*" + $Filters[$Index] + "*"
                }
            }
        }

        ## Run query
        if ("COM","Types","WMI" -contains $Type) {
            ## Construct query from multiple filters
            $Query = "Name LIKE '$($Filters[0])'"
            foreach ($Filter in $Filters[1..($Filters.Count - 1)]) {
                $Query += " AND Name LIKE '$Filter'"
            }
            switch -exact ($Type) {
                "COM" {
                    $dsTabExpansionDatabase.Tables[$Type].Select($Query) |
                        Select-Object Name,Description | RetypeObject "PowerTab.TabExpansion.COMItem"
                }
                "Types" {
                    $dsTabExpansionDatabase.Tables[$Type].Select($Query) |
                        Select-Object Name,DC,NS | RetypeObject "PowerTab.TabExpansion.TypeItem"
                }
                "WMI" {
                    $dsTabExpansionDatabase.Tables[$Type].Select($Query) |
                        Select-Object Name,Description | RetypeObject "PowerTab.TabExpansion.WMIItem"
                }
            }
        } else {
            ## Construct query from multiple filters
            $Query = "Filter LIKE '$($Filters[0])'"
            foreach ($Filter in $Filters[1..($Filters.Count - 1)]) {
                $Query += " AND Filter LIKE '$Filter'"
            }
            $dsTabExpansionDatabase.Tables["Custom"].Select("$Query AND Type LIKE '$Type'") |
                Select-Object Filter,Text,Type | RetypeObject "PowerTab.TabExpansion.Item"
        }

        trap [PipelineStoppedException] {
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
        ## Do not allow duplicate computer entries
        if ($Type -eq "Computer") {
            if (Get-TabExpansion -Filter $Filter -Type $Type) {
                ## TODO: Localize!
                Write-Verbose "Found duplicate Computer entry for '$Filter'.  Ignoring."
                return
            }
        }

        [Void]$dsTabExpansionDatabase.Tables['Custom'].Rows.Add($Filter, $Text, $Type)

        trap [PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}
Set-Alias ate Add-TabExpansion


# .ExternalHelp TabExpansionLib-Help.xml
Function Remove-TabExpansion {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter
    )

    ## TODO: Add type
    process {
        $Filter = $Filter -replace "\*","%"

        foreach ($Item in $dsTabExpansionDatabase.Tables['Custom'].Select("Filter LIKE '$Filter'")) {
            $Item.Delete()
        }

        trap [PipelineStoppedException] {
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
        [System.Version]$CurVersion = (Parse-Manifest).ModuleVersion

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

        trap [PipelineStoppedException] {
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
        $Config = InternalImportTabExpansionConfig $ConfigurationPath
    } else {
        ## Configuration path does not exist
        Write-Warning "Specified configuration path does not exist."  ## TODO: Localize
        $Config = InternalNewTabExpansionConfig $ConfigurationPath
    }

    ## Load Version
    [System.Version]$CurVersion = (Parse-Manifest).ModuleVersion
    $Version = $Config.Tables['Config'].Select("Name = 'Version'")[0].Value -as [System.Version]

    ## Load Database
    if ($Version -lt ([System.Version]'0.99.3.0')) {
        $DatabaseName = $Config.Tables['Config'].select("Name = 'DatabaseName'")[0].Value
        $DatabasePath = Join-Path ($Config.Tables['Config'].select("Name = 'DatabasePath'")[0].Value) $DatabaseName
    } else {
        $DatabasePath = $Config.Tables['Config'].select("Name = 'DatabasePath'")[0].Value
    }
    if (!(Split-Path $DatabasePath)) {
        $DatabasePath = Join-Path $PSScriptRoot $DataBasePath
    }

    $Database = InternalImportTabExpansionDataBase $DatabasePath

    ## Upgrade if needed
    $UpgradeOccurred = $false
    if ($Version -lt $CurVersion) {
        ## Upgrade config and database
        $UpgradeOccurred = UpgradeTabExpansionDatabase ([Ref]$Config) ([Ref]$Database) $Version
    } elseif ($Version -gt $CurVersion) {
        ## Config is from a newer version
        throw "The configuration was created with a newer version of PowerTab and is not compatible."
    }

    ## Config and database are good
    $script:dsTabExpansionConfig = $Config
    $script:dsTabExpansionDatabase = $Database

    ## Create the user interface for the PowerTab settings
    CreatePowerTabConfig

    ## Set version
    $PowerTabConfig.Version = $CurVersion

    ## Export the newly upgraded config and database
    if ($UpgradeOccurred) {
        Export-TabExpansionConfig
        Export-TabExpansionDatabase
    }
}


Function UpgradeTabExpansionDatabase {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
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

    $UpgradeOccurred = $false

    if ($Version -lt [System.Version]'0.99.3.0') {
        ## Upgrade versions from the first version of PowerTab
        Write-Host "Upgrading from version $Version"  ## TODO:  Localize
        UpgradePowerTab99 $Config $Database
        $Version = '0.99.3.0'
        $UpgradeOccurred = $true
    }
    if ($Version -lt [System.Version]'0.99.5.0') {
        ## Upgrade versions from the first version of PowerTab
        Write-Host "Upgrading from version $Version"  ## TODO:  Localize
        UpgradePowerTab993 $Config $Database
        $Version = '0.99.5.0'
        $UpgradeOccurred = $true
    }
    if ($Version -lt [System.Version]'1.0.0.0') {
        ## Upgrade versions from the first version of PowerTab
        Write-Host "Upgrading from version $Version"  ## TODO:  Localize
        UpgradePowerTab100 $Config $Database
        $Version = '1.0.0.0'
        $UpgradeOccurred = $true
    }

    return $UpgradeOccurred
}


Function UpgradePowerTab99 {
    [CmdletBinding()]
    param(
        [Ref]$Config
        ,
        [Ref]$Database
    )

    $Config.Value.Tables['Config'].Select("Name = 'InstallPath' AND Category = 'Setup'") | ForEach-Object {$_.Delete()}
    if ($Database.Value.Tables['Config']) {
        $Database.Value.Tables.Remove('Config')
        trap {continue}
    }
    if ($Database.Value.Tables['Cache']) {
        $Database.Value.Tables.Remove('Cache')
        trap {continue}
    }
    $ConfigurationPath = $Config.Value.Tables['Config'].Select("Name = 'ConfigurationPath'")[0].Value
    $Config.Value.Tables['Config'].Select("Name = 'ConfigurationPath'")[0].Value = Join-Path $ConfigurationPath "PowerTabConfig.xml"
    $DatabasePath = $Config.Value.Tables['Config'].Select("Name = 'DatabasePath'")[0].Value
    $DatabaseName = $Config.Value.Tables['Config'].Select("Name = 'DatabaseName'")[0].Value
    $Config.Value.Tables['Config'].Select("Name = 'DatabasePath'")[0].Value = Join-Path $DatabasePath $DatabaseName
    $Config.Value.Tables['Config'].Select("Name = 'DatabaseName' AND Category = 'Setup'") | ForEach-Object {$_.Delete()}
}


Function UpgradePowerTab993 {
    [CmdletBinding()]
    param(
        [Ref]$Config
        ,
        [Ref]$Database
    )

    $Config.Value.Tables['Config'].Select("Name = 'SpaceCompleteFileSystem'") | ForEach-Object {$_.Delete()}
    ## Add VisualStudioTabBehavior
    $row = $Config.Value.Tables['Config'].NewRow()
    $row.Name = 'VisualStudioTabBehavior'
    $row.Type = 'Bool'
    $row.Category = 'Global'
    $row.Value = [Int]($False)
    $Config.Value.Tables['Config'].Rows.Add($row)
}


Function UpgradePowerTab100 {
    [CmdletBinding()]
    param(
        [Ref]$Config
        ,
        [Ref]$Database
    )

    $DefaultHandler = $Config.Value.Tables['Config'].Select("Name = 'DefaultHandler'")[0]
    $AlternateHandler = $Config.Value.Tables['Config'].Select("Name = 'AlternateHandler'")[0]
    if ($DefaultHandler.Value -eq "Intellisense") {
        $DefaultHandler.Value = "Dynamic"
    }
    if ($AlternateHandler.Value -eq "Intellisense") {
        $AlternateHandler.Value = "Dynamic"
    }
    $DefaultHandler.Category = "Core"
    $AlternateHandler.Category = "Core"

    ## Convert Core settings
    $Config.Value.Tables['Config'].Select("Name = 'DoubleTabEnabled'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'DoubleTabLock'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'AliasQuickExpand'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'CustomFunctionEnabled'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'CustomUserFunction'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'FileSystemExpand'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'ShowAccessorMethods'")[0].Category = "Core"
    $Config.Value.Tables['Config'].Select("Name = 'IgnoreConfirmPreference'")[0].Category = "Core"

    ## Convert ConsoleList settings
    $Config.Value.Tables['Config'].Select("Name = 'MinimumListItems'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'FastScrollItemcount'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'CloseListOnEmptyFilter'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'VisualStudioTabBehavior'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'DotComplete'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'AutoExpandOnDot'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'BackSlashComplete'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'AutoExpandOnBackSlash'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'SpaceComplete'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'CustomComplete'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'CustomCompletionChars'")[0].Category = "ConsoleList"
    $Config.Value.Tables['Config'].Select("Name = 'DoubleBorder'")[0].Category = "ConsoleList"
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
    ([Ordered]@{
            Version = (Parse-Manifest).ModuleVersion
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'Global'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}
    @($dtConfig.Select("Name = 'Version'"))[0].Category = 'Version'
    ([Ordered]@{
            Enabled = $True
            TabActivityIndicator = $True
            ShowBanner = $True
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Bool'
            $row.Category = 'Global'
            $row.Value = [Int]($_.Value)
            $dtConfig.Rows.Add($row)
        }}

    ## Add setup configuration
    ([Ordered]@{
            ConfigurationPath = $ConfigurationPath
            DatabasePath = $DatabasePath
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'Setup'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}

    ## Add Core configuration
    ([Ordered]@{
            DefaultHandler = 'Dynamic'
            AlternateHandler = 'Dynamic'
            CustomUserFunction = 'Write-Warning'
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'Core'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}
    ([Ordered]@{
            CustomFunctionEnabled = $False
            DoubleTabEnabled = $False
            DoubleTabLock = $False
            AliasQuickExpand = $False
            FileSystemExpand = $True
            ShowAccessorMethods = $True
            IgnoreConfirmPreference = $False
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Bool'
            $row.Category = 'Core'
            $row.Value = [Int]($_.Value)
            $dtConfig.Rows.Add($row)
        }}
    ([Ordered]@{
            Alias   = '@'
            Partial = '%'
            Native  = '!'
            Invoke  = '&'
            Custom  = '^'
            CustomFunction  = '#'
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'ShortcutChars'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}

    ## Add ConsoleList configuration
    ([Ordered]@{
            MinimumListItems   = '2'
            FastScrollItemcount = '10'
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Int'
            $row.Category = 'ConsoleList'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}
    ([Ordered]@{
            CloseListOnEmptyFilter = $True
            VisualStudioTabBehavior = $False
            DotComplete = $True
            AutoExpandOnDot = $True
            BackSlashComplete = $True
            AutoExpandOnBackSlash = $True
            SpaceComplete = $True
            DoubleBorder = $True
            CustomComplete = $True
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'Bool'
            $row.Category = 'ConsoleList'
            $row.Value = [Int]($_.Value)
            $dtConfig.Rows.Add($row)
        }}
    ([Ordered]@{
            CustomCompletionChars = ']:)'
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Type = 'String'
            $row.Category = 'ConsoleList'
            $row.Value = $_.Value
            $dtConfig.Rows.Add($row)
        }}
    ([Ordered]@{
            TextColor = "Yellow"
            BackColor = "DarkGray"
            BorderColor = "Blue"
            BorderBackColor = "DarkBlue"
            SelectedTextColor = "Red"
            SelectedBackColor = "DarkRed"
            BorderTextColor = "Yellow"
            FilterColor = "DarkGray"
        }).GetEnumerator() | . {process{
            $row = $dtConfig.NewRow()
            $row.Name = $_.Name
            $row.Category = 'Colors'
            $row.Type = 'ConsoleColor'
            $row.Value = [ConsoleColor]($_.Value)
            $dtConfig.Rows.Add($row)
        }}

    $Config.Tables.Add($dtConfig)
    $Config
}


Function InternalImportTabExpansionDataBase {
    [CmdletBinding()]
    param(
        [String]$LiteralPath
    )

    $Database = New-Object System.Data.DataSet
    if (($LiteralPath -eq "IsolatedStorage") -and (Test-IsolatedStoragePath "PowerTab/TabExpansion.xml")) {
        $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
        $IsoFile = New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream("PowerTab/TabExpansion.xml",
            [System.IO.FileMode]::Open, $UserIsoStorage)
        [Void]$Database.ReadXml($IsoFile)
    } elseif (Test-Path $LiteralPath) {
        if (![System.IO.Path]::IsPathRooted($LiteralPath)) {
            $LiteralPath = Resolve-Path $LiteralPath
        }
        [Void]$Database.ReadXml($LiteralPath)
    }

    if (!$Database.Tables["COM"]) {
        $dtCom = New-Object System.Data.DataTable
        [Void]($dtCom.Columns.Add('Name', [String]))
        [Void]($dtCom.Columns.Add('Description', [String]))
        $dtCom.TableName = 'COM'
        $Database.Tables.Add($dtCom)
    }
    if (!$Database.Tables["Custom"]) {
        $dtCustom = New-Object System.Data.DataTable
        [Void]($dtCustom.Columns.Add('Filter', [String]))
        [Void]($dtCustom.Columns.Add('Text', [String]))
        [Void]($dtCustom.Columns.Add('Type', [String]))
        $dtCustom.TableName = 'Custom'
        $Database.Tables.Add($dtCustom)
    }
    if (!$Database.Tables["Types"]) {
        $dtTypes = New-Object System.Data.DataTable
        [Void]($dtTypes.Columns.Add('Name', [String]))
        [Void]($dtTypes.Columns.Add('DC', [String]))
        [Void]($dtTypes.Columns.Add('NS', [String]))
        $dtTypes.TableName = 'Types'
        $Database.Tables.Add($dtTypes)
    }
    if (!$Database.Tables["WMI"]) {
        $dtWmi = New-Object System.Data.DataTable
        [Void]($dtWmi.Columns.Add('Name', [String]))
        [Void]($dtWmi.Columns.Add('Description', [String]))
        $dtWmi.TableName = 'WMI'
        $Database.Tables.Add($dtWmi)
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
        $IsoFile = New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream("PowerTab/PowerTabConfig.xml",
            [System.IO.FileMode]::Open, $UserIsoStorage)
        [Void]$Config.ReadXml($IsoFile, 'InferSchema')
    } elseif (Test-Path $LiteralPath) {
        if (![System.IO.Path]::IsPathRooted($LiteralPath)) {
            $LiteralPath = Resolve-Path $LiteralPath
        }
        [Void]$Config.ReadXml($LiteralPath, 'InferSchema')
    } else {
        $Config = InternalNewTabExpansionConfig $LiteralPath
    }

    $Version = $Config.Tables['Config'].Select("Name = 'Version'")[0].Value -as [System.Version]
    if ($null -eq $Version) {$Config.Tables['Config'].Select("Name = 'Version'")[0].Value = '0.99.0.0'}

    $Config
}


Function CreatePowerTabConfig {
    [CmdletBinding()]
    param()
    
    $script:PowerTabConfig = New-Object PSObject

    ## Make global properties on config object
    Add-Member -InputObject $PowerTabConfig -MemberType ScriptProperty -Name Version `
        -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$dsTabExpansionConfig.Tables['Config'].Select(`"Name = 'Version'`")[0].Value") `
        -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
            "trap {Write-Warning `$_; continue}
            `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = 'Version'`")[0].Value = [String]`$args[0]")
    Add-Member -InputObject $PowerTabConfig -MemberType ScriptProperty -Name Enabled `
        -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = 'Enabled'`")[0]
            [Bool][Int]`$v.Value") `
        -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
            "trap {Write-Warning `$_; continue}
            [Int]`$val = [Bool]`$args[0]
            `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = 'Enabled'`")[0].Value = `$val
            if ([Bool]`$val) {
                . `"$PSScriptRoot/TabExpansion.ps1`"
            } else {
                Set-Content Function:\TabExpansion -Value `$OldTabExpansion
            }") `
        -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Global'") | Where-Object {$_.Name -ne "Enabled"} | . {process{
        Add-Member -InputObject $PowerTabConfig -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0]
                if (`$v.Type -eq 'Bool') {
                    [Bool][Int]`$v.Value
                } else {
                    [$($_.Type)](`$v.Value)
                }") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$val = [$($_.Type)]`$args[0]
                    if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = `$val") `
            -Force
    }}

    ## Make Setup properties on config object
    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Setup -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.Setup -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Setup Data}"} -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Setup'") | . {process{
        Add-Member -InputObject $PowerTabConfig.Setup -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0]
                if (`$v.Type -eq 'Bool') {
                    [Bool][Int]`$v.Value
                } else {
                    [$($_.Type)](`$v.Value)
                }") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$val = [$($_.Type)]`$args[0]
                 if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = `$val") `
            -Force
    }}
    
    ## Make properties for Core features
    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Core -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.Core -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Core Behavior}"} -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Core'") | . {process{
        Add-Member -InputObject $PowerTabConfig.Core -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0]
                if (`$v.Type -eq 'Bool') {
                    [Bool][Int]`$v.Value
                } else {
                    [$($_.Type)](`$v.Value)
                }") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$val = [$($_.Type)]`$args[0]
                    if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = `$val") `
            -Force
    }}
    Add-Member -InputObject $PowerTabConfig.Core -MemberType NoteProperty -Name ShortcutChars -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.Core.ShortcutChars -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Shortcut Characters}"} -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'ShortcutChars'") | . {process{
        Add-Member -InputObject $PowerTabConfig.Core.ShortcutChars -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = `$args[0]") `
            -Force
    }}

    ## Make properties for Console List
    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name ConsoleList -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.ConsoleList -MemberType ScriptMethod -Name ToString -Value {"{ConsoleList Configuration}"} -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'ConsoleList'") | . {process{
        Add-Member -InputObject $PowerTabConfig.ConsoleList -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$v = `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0]
                if (`$v.Type -eq 'Bool') {
                    [Bool][Int]`$v.Value
                } else {
                    [$($_.Type)](`$v.Value)
                }") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$val = [$($_.Type)]`$args[0]
                 if ('$($_.Type)' -eq 'bool') {`$val = [Int]`$val}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = `$val") `
            -Force
    }}
    Add-Member -InputObject $PowerTabConfig.ConsoleList -MemberType NoteProperty -Name Colors -Value (New-Object PSObject)
    Add-Member -InputObject $PowerTabConfig.ConsoleList.Colors -MemberType ScriptMethod -Name ToString -Value {"{ConsoleList Color Configuration}"} -Force
    $dsTabExpansionConfig.Tables['Config'].Select("Category = 'Colors'") | . {process{
        Add-Member -InputObject $PowerTabConfig.ConsoleList.Colors -MemberType ScriptProperty -Name $_.Name `
            -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
                "`$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value") `
            -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap {Write-Warning `$_; continue}
                `$dsTabExpansionConfig.Tables['Config'].Select(`"Name = '$($_.Name)'`")[0].Value = [ConsoleColor]`$args[0]") `
            -Force
    }}
    
    $Logs = [Ordered]@{
        Error = New-Object System.Collections.ArrayList
        History = New-Object System.Collections.ArrayList
        Trace = New-Object System.Collections.ArrayList
        TraceEnabled = $true
    }
    Add-Member -InputObject $PowerTabConfig -MemberType NoteProperty -Name Log -Value (
        New-Object PSObject -Property $Logs
    )
    Add-Member -InputObject $PowerTabConfig.Log -MemberType ScriptMethod -Name ToString -Value {"{PowerTab Logs}"} -Force
}
