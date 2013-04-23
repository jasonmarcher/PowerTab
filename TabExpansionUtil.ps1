# TabExpansionUtil.ps1
#
# 


#########################
## Private functions
#########################

Function Out-DataGridView {
    [CmdletBinding()]
    param(
		[Parameter(Position = 0)]
        [String]
        $ReturnField
        ,
		[Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $InputObject
    )

    begin {
        [Object[]]$Objects = @()
    }

    process {
        $Objects += $InputObject
    }

    end {
        # Make DataTable from Input
        $dt = New-Object System.Data.DataTable
        $First = $true
        foreach ($Item in $Objects) {
            $dr = $dt.NewRow()
            $Item.PSObject.get_Properties() | ForEach-Object {
                if ($first) {
                    $col =  New-Object System.Data.DataColumn
                    $col.ColumnName = $_.Name.ToString()
                    $dt.Columns.Add($col)
                }
                if ($_.Value -eq $null) {
                    $dr.Item($_.Name) = "[empty]"
                } elseif ($_.IsArray) {
                    $dr.Item($_.Name) =[String]::Join($_.Value ,";")
                } else {
                    $dr.Item($_.Name) = $_.Value
                }
            }
            $dt.Rows.Add($dr)
            $First = $false
        }

        # Show Datatable in Form
        $form = New-Object System.Windows.Forms.Form
        $form.Size = new-Object System.Drawing.Size @(1000,600)
        $dg = New-Object System.Windows.Forms.DataGridView
        $dg.DataSource = $dt.PSObject.BaseObject
        $dg.Dock = [System.Windows.Forms.DockStyle]::Fill
        $dg.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
        $dg.SelectionMode = 'FullRowSelect'
        $dg.add_DoubleClick({
            $script:ret = $this.SelectedRows | ForEach-Object {$_.DataBoundItem["$ReturnField"]}
            $form.Close()
        })

        $form.Text = "$($MyInvocation.Line)"
        $form.KeyPreview = $true
        $form.add_KeyDown({
            if ($_.KeyCode -eq 'Enter') {
                $script:ret = $dg.SelectedRows | ForEach-Object {$_.DataBoundItem["$ReturnField"]}
                $form.Close()
            } elseif ($_.KeyCode -eq 'Escape') {
                $form.Close()
            }
        })

        $form.Controls.Add($dg)
        $form.add_Shown({$form.Activate(); $dg.AutoResizeColumns()})
        $script:ret = $null
        [Void]$form.ShowDialog()
        $script:ret
    }
}

############

Function Resolve-Command {
    [CmdletBinding()]
    param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
        ,
        [Switch]
        $CommandInfo
    )

    process {
        $Command = ""

        ## Get command info
        if ($Name -match "\\") {
            ## Full name usage
            $Module = $Name.Substring(0, $Name.Indexof("\"))
            $CommandName = $Name.Substring($Name.Indexof("\") + 1, $Name.length - ($Name.Indexof("\") + 1))
            if ($Module = Get-Module $Module) {
                $Command = @(GetCommand $CommandName -Module $Module)[0]
                if (-not $Command) {
                    ## Try to look up command with prefix
                    $Prefix = Get-CommandPrefix $Module
                    $Verb = $CommandName.Substring(0, $CommandName.Indexof("-"))
                    $Noun = $CommandName.Substring($CommandName.Indexof("-") + 1, $CommandName.length - ($CommandName.Indexof("-") + 1))
                    $Command = @(GetCommand "$Verb-$Prefix$Noun")[0]
                }
                if (-not $Command) {
                    ## Try looking in the module's exported command list
                    $Command = $Module.ExportedCommands[$CommandName]
                }
            }
        }
        if (-not $Command) {
            try {
                ## This try is to provide a second chance to catch automatic aliases for Get-* commands
                if ($Name.Contains("?")) {
                    ## The where clause prevents problems with "?" wildcard
                    $Command = @(GetCommand $Name | Where-Object {$_.Name -eq $Name})[0]
                } else {
                    $Command = @(GetCommand $Name)[0]
                }
            } catch {
                if (-not ($Command = try {@(GetCommand "Get-$Name")[0]} catch {})) {
                    throw $_
                }
            }
        }

        if ($Command.CommandType -eq "Alias") {
            $Command = $Command.ResolvedCommand	
        }

        ## Return result
        if ($CommandInfo) {
            $Command
        } else {
            if ($Command.CommandType -eq "ExternalScript") {
                $Command.Path
            } else {
                $Command.Name
            }
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

Function Resolve-Parameter {
    [CmdletBinding(DefaultParameterSetName = "Command")]
    param(
		[Parameter(ParameterSetName = "Command", Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Command
        ,
		[Parameter(ParameterSetName = "CommandInfo", Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.CommandInfo]
        $CommandInfo
        ,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
        ,
        [Switch]
        $ParameterInfo
    )

    process {
        ## Remove leading dash if it exists
        $Name = $Name -replace '^-'

        ## Get command info
		if ($PSCmdlet.ParameterSetName -eq "Command") {
            $CommandInfo = Resolve-Command $Command -CommandInfo
        } elseif ($PSCmdlet.ParameterSetName -eq "CommandInfo") {
            if ($CommandInfo -eq $null) {return}
        }

        ## Check if this is a real parameter name and not an alias
        if ($CommandInfo.Parameters["$Name"]) {
            $Parameter = $CommandInfo.Parameters["$Name"]
        } else {
            ## Possible alias
            $Parameter = @($CommandInfo.Parameters.Values | Where-Object {$_.Aliases -contains $Name})[0]
        }

        ## If no parameter found, it could be an abreviated name (-comp instead of -ComputerName)
        if (-not $Parameter) {
            $Parameter = @($CommandInfo.Parameters.Values | Where-Object {$_.Name -like "$Name*"})[0]
        }

        ## Return result
        if ($ParameterInfo) {
            $Parameter
        } else {
            $Parameter.Name
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

Function Resolve-PositionalParameter {
    param(
		[Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [Object]
        $Context
    )
    
    process {
        if ($TabExpansionCommandInfoRegistry[$Context.Command]) {
            $ScriptBlock = $TabExpansionCommandInfoRegistry[$Context.Command]
            $CommandInfo = & $ScriptBlock $Context
            if (-not $CommandInfo) {throw "foo"} ## TODO
        } elseif ($Context.CommandInfo) {
            $CommandInfo = $Context.CommandInfo
        } else {
            return $Context
        }

        foreach ($ParameterSet in $CommandInfo.ParameterSets) {
            $PositionalParameters = @($ParameterSet.Parameters |
                Where-Object {($_.Position -ge 0) -and ($Context.OtherParameters.Keys -notcontains $_.Name)} | Sort-Object Position)

            if (($Context.PositionalParameter -ge 0) -and ($Context.PositionalParameter -lt $PositionalParameters.Count)) {
                ## TODO: Try to figure out a better parameter?
                $Context.Parameter = $PositionalParameters[$Context.PositionalParameter].Name
                #$Context.PositionalParameter -= 1
                break
            } elseif ($PositionalParameters[-1].ValueFromRemainingArguments) {
                $Context.Parameter = $PositionalParameters[-1].Name
                break
            }
        }

        $Context

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

Function Resolve-InternalCommandName {
    [CmdletBinding(DefaultParameterSetName = "Command")]
    param(
		[Parameter(ParameterSetName = "Command", Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Command
        ,
		[Parameter(ParameterSetName = "CommandInfo", Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.CommandInfo]
        $CommandInfo
    )

    process {
        ## Get command info
		if ($PSCmdlet.ParameterSetName -eq "Command") {
            $CommandInfo = Resolve-Command $Command -CommandInfo
        }

        ## Return result
        if ($Prefix = Get-CommandPrefix $CommandInfo) {
            $Verb = $CommandInfo.Name.Substring(0, $CommandInfo.Name.Indexof("-"))
            $Noun = $CommandInfo.Name.Substring($CommandInfo.Name.Indexof("-") + 1, $CommandInfo.Name.length - ($CommandInfo.Name.Indexof("-") + 1))
            $Noun = $Noun -replace [Regex]::Escape($Prefix)
            $InternalName = "$Verb-$Noun"
        } else {
            $InternalName = $CommandInfo.Name
        }

        New-Object PSObject -Property @{"InternalName"=$InternalName;"Module"=$CommandInfo.Module}

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

Function Get-CommandPrefix {
    [CmdletBinding(DefaultParameterSetName = "Command")]
    param(
		[Parameter(ParameterSetName = "Command", Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [String]
        $Command
        ,
		[Parameter(ParameterSetName = "CommandInfo", Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.CommandInfo]
        $CommandInfo
        ,
		[Parameter(ParameterSetName = "ModuleInfo", Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.PSModuleInfo]
        $ModuleInfo
    )

    process {
        ## Get module info
		if ($PSCmdlet.ParameterSetName -eq "Command") {
            $ModuleInfo = (Resolve-Command $Command -CommandInfo).Module
        } elseif (($PSCmdlet.ParameterSetName -eq "CommandInfo") -and $CommandInfo.Module) {
            $ModuleInfo = Get-Module $CommandInfo.Module
        }

        if ($ModuleInfo) {
            $CommandGroups = $ModuleInfo.ExportedFunctions.Values +
                (Get-Command -Module $ModuleInfo -CommandType Function,Filter,Cmdlet) | Group-Object {$_.Definition}
            $Prefixes = foreach ($Group in $CommandGroups) {
                $Names = $Group.Group | Select-Object -ExpandProperty Name
                $TempNoun = (@($Names)[0] -split "-")[1]
            	foreach($Name in $Names) {
            		if ($Name -match "-") {
            			$PossiblePrefix = $Name.SubString($Name.IndexOf("-") + 1, $Name.LastIndexOf($TempNoun) - $Name.IndexOf("-") - 1)
                        if ($PossiblePrefix) {
                            $PossiblePrefix
                        }
            		}
            	}
            }

            if ($Prefixes.Count) {
                $Prefixes | Select-Object -Unique
            } else {
                $Prefixes
            }
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

Function GetCommand {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String]$Name
        ,
        [String]$Module
        ,
        [System.Management.Automation.CommandTypes]$CommandType = "All"
    )

    end {
        ## The closures prevent internal PowerTab methods from being shown.
        if ($PSVersionTable.PSVersion -eq "2.0") {
            & {Get-Command $Name -Module $Module -CommandType $CommandType -ErrorAction SilentlyContinue}.GetNewClosure()
        } else {
            if ($Module) {
                $Name = "$Module\$Name"
            }
            & {$ExecutionContext.InvokeCommand.GetCommands($Name, $CommandType, $true) | Sort-Object Name}.GetNewClosure()
        }
    }
}

############

Function Resolve-TabExpansionParameterValue {
    param(
        [String]$Value
    )

    switch -regex ($Value) {
        '^\$' {
            [String](Invoke-Expression $_)
            break
        }
        '^\(.*\)$' {
            [String](Invoke-Expression $_)
            break
        }
        Default {$Value}
    }
}

############


Function Invoke-ProviderPathHandler {
    [CmdletBinding()]
    param(
		[Parameter(Position = 0)]
        [String]
        $Path
    )

    end {
        Write-Trace "Executing FileSystem completion."

        $PowerTabFileSystemMode = $true
        $Path = $Path -replace '`'

        ## 
        $PathSlices = [Regex]::Split($Path, '\\|/')
        if ($PathSlices.Count -eq 1) {
            if ($PathSlices[0] -like "*:") {
                ## Add a trailing backslash if only a drive name
                $Path = $PathSlices[0] + "\"
                $PathSlices = $PathSlices,""
            } else {
                ## Convert single words to a more exact path
                $PathSlices = ,"." + $PathSlices
            }
        }
        if ($PathSlices[0] -eq "~") {
            ## Resolve reference to HOME folder for use outside PS
            $PathSlices[0] = try {Resolve-Path "~"} catch {$PathSlices[0]}
        }
        $Container = [String]::Join('\', $PathSlices[0..($PathSlices.Count - 2)])
        $LastPath = $Container + "\$([Regex]::Split($Path,'\\|/|:')[-1])"

        ## TODO: replace with calls to new function
        if (("Push-Location","Set-Location") -contains $Context.Command) {
            $ChildItems = @(Get-ChildItem "$Path*" | Where-Object {$_.PSIsContainer})
        } else {
            $ChildItems = @(Get-ChildItem "$Path*")
        }

        ## If no matches, return
        if (-not $ChildItems) {$Path; return}

        ## Add entry for parent ("..")
        #if ((@($childitems).count -eq 1) -and ($Path.endswith('\')) ) {$childitems = $childitems,@{name='..'}}

        ## Fixes paths for registry keys, certificates and other unusual paths
        ## Improved fix for a problem identified by idvorkin (http://poshcode.org/1586)
        $ChildItems = foreach ($Item in $ChildItems) {
            $Child = switch ($Item.GetType().FullName) {
                "System.Security.Cryptography.X509Certificates.X509Certificate2" {$Item.Thumbprint;break}
                "Microsoft.Powershell.Commands.X509StoreLocation" {$Item.Location;break}
                "Microsoft.Win32.RegistryKey" {$Item.Name.Split("\")[-1];break}
                default {$Item.Name}
            }
            $Type = switch ($Item.GetType().FullName) {
                "System.IO.DirectoryInfo" {"Directory";break}
                "System.IO.FileInfo" {"File";break}
                "System.Management.Automation.AliasInfo" {"Alias";break}
                "System.Management.Automation.FilterInfo" {"Command";break}
                "System.Management.Automation.FunctionInfo" {"Command";break}
                "System.Security.Cryptography.X509Certificates.X509Certificate2" {"Certificate";break}
                "Microsoft.Powershell.Commands.X509StoreLocation" {"CertificateStore";break}
                "Microsoft.Win32.RegistryKey" {"RegistryKey";break}
                default {$_}
            }
            New-TabItem "$Container\$Child" "$Container\$Child" -Type $Type
        }
        $ChildItems | Invoke-TabItemSelector $LastPath -SelectionHandler $SelectionHandler -Return $Path -ForceList:$ForceList | ForEach-Object {
            ## If a path contains any of these characters it needs to be in quotes
            $_charsRequiringQuotes = ('`&@''#{}()$,; ' + "`t").ToCharArray()
        } {
            $Quote = ''
            $Invoke = ''

            if (($LastBlock -notmatch ".*['`"]`$") -and (-not $NestedPowerTab)) {  ## Don't quote if it looks like the path is already quoted
                if ($_ -is [String]) {
                    ## Remove quotes from beginning and end of string
                    $_ = $_ -replace '^"|"$'
                    ## Escape certain characters
                    $_ = $_ -replace '([\$"`])','`$1'

                    if ($_.IndexOfAny($_charsRequiringQuotes) -ge 0) {
                        ## Check for quotes in the last block of the input line,
                        ## if they exist, PowerShell will add them to this output
                        ## if not, then quotes can safely be added
                        if (-not (@([Char[]]$LastBlock | Where-Object {$_ -match '"|'''}).Count % 2)) {$Quote = '"'}
                        if (($LastBlock.Trim() -eq $Path)) {$Invoke = '& '}
                    }
                    "$Invoke$Quote$_$Quote"
                } else {
                    ## Remove quotes from beginning and end of string
                    $_.Value = $_.Value -replace '^"|"$'
                    ## Escape certain characters
                    $_.Value = $_.Value -replace '([\$"`])','`$1'

                    if ($_.Value.IndexOfAny($_charsRequiringQuotes) -ge 0) {
                        ## Check for quotes in the last block of the input line,
                        ## if they exist, PowerShell will add them to this output
                        ## if not, then quotes can safely be added
                        if (-not (@([Char[]]$LastBlock | Where-Object {$_ -match '"|'''}).Count % 2)) {$Quote = '"'}
                        if (($LastBlock.Trim() -eq $Path)) {$Invoke = '& '}
                    }
                    $_.Value = "$Invoke$Quote$($_.Value)$Quote"
                    $_
                }
            } else {
                ## Need to return the value if we are not quoting
                $_
            }
        }
    }
}

############


Function RetypeObject {
    [CmdletBinding()]
    param(
		[Parameter(Position = 0)]
        [String]
        $Type
        ,
		[Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $InputObject
    )

    process {
        $InputObject.PSObject.TypeNames.Insert(0, $Type)
        $InputObject
    }
}

## Slightly modified from http://blog.sapien.com/index.php/2009/08/24/writing-form-centered-scripts-with-primalforms/
Function Get-GuiDate {
    param(
       [Int]$DisplayMode = 1, # number of months to show
       [Int]$SelectionCount = 0, # number of days that can be selected
       [DateTime]$TodayDate = $(Get-Date), # sets default selected date
       [DateTime]$DateSelected = $TodayDate, # sets default selected date
       [Int]$FirstDayofWeek = -1, # -1 used default - calendar dayofweek, NOT datetime
       [DateTime[]]$Bold = @(), # Array of bolded dates to add
       [DateTime[]]$YBold = @(), # annual bolded dates to add
       [DateTime[]]$MBold = @(), # monthly bolded dates to add
       [Int]$ScrollBy = $DisplayMode, # number of months to scroll by; 0 = screenfull
       [Switch]$WeekNumbers, # Show numeric week of year on the display
       [String]$Title = "Get-GuiDate",
       [Switch]$NoTodayCircle,
       [DateTime]$MinDate = "1753-01-01",
       [DateTime]$MaxDate = "9998-12-31"
    )

    [System.Windows.Forms.Application]::EnableVisualStyles()
    # Is this voodoo code, or not?
    [System.Windows.Forms.Application]::DoEvents()

    $cal = New-Object Windows.Forms.MonthCalendar
    $cal.SetDate($DateSelected)
    $cal.TodayDate = $TodayDate
    if ($SelectionCount -lt 1) {$SelectionCount = [int]::MaxValue}
    $cal.MaxSelectionCount = $SelectionCount
    $cal.MinDate = $MinDate
    $cal.MaxDate = $MaxDate
    $cal.ScrollChange = $ScrollBy
    $cal.ShowTodayCircle = $true
    if ($FirstDayofWeek -eq -1) {$FirstDayofWeek = [System.Windows.Forms.Day]::Default}
    $cal.FirstDayofWeek = [System.Windows.Forms.Day]$FirstDayofWeek
    $cal.ShowWeekNumbers = $WeekNumbers
    if ($NoTodayCircle) {$cal.ShowTodayCircle = $False}

    # Provides clean display geometry
    switch -regex ($DisplayMode) {
        "^1$" {$cal.CalendarDimensions = "1,1"}
        "^2$" {$cal.CalendarDimensions = "2,1"}
        "^3$" { $cal.CalendarDimensions = "3,1"}
        "^4$" {$cal.CalendarDimensions = "2,2"}
        "^[56]$" {$cal.CalendarDimensions = "3,2"}
        "^[78]$" {$cal.CalendarDimensions = "4,2"}
        "^9$" {$cal.CalendarDimensions = "3,3"}
        "^1[012]$" {$cal.CalendarDimensions = "4,3"}
        default {$cal.CalendarDimensions = "4,4"}
    }

    if ($Bold) {$cal.BoldedDates = $Bold}
    if ($YBold) {$cal.AnnuallyBoldedDates = $YBold}
    if ($MBold) {$cal.MonthlyBoldedDates = $MBold}

    $form = New-Object Windows.Forms.Form
    $form.AutoSize = $form.TopMost = $form.KeyPreview = $True
    $form.MaximizeBox = $form.MinimizeBox = $False
    $form.AutoSizeMode = "GrowAndShrink"
    $form.Controls.Add($cal)
    $form.BackColor = [System.Drawing.Color]::White
    $form.Text = $Title

    # We'll handle escape or enter to get out.
    $Escaped = $False;
    $form.Add_KeyDown([System.Windows.Forms.KeyEventHandler]{
        if ($_.KeyCode -eq "Escape") {
            $Escaped = $true; $form.Close()
        } elseif ($_.KeyCode -eq "Enter") {
            $form.Close()
        }
    })

    # Ensures the form is on top, is active, and then shows it.
    # After calling ShowDialog(), the script is blocked until
    # the form is no longer visible.
    $form.Add_Shown({$form.Activate()}) 
    [Void]$form.ShowDialog()

    # If they didn't press Escape, output the selection range
    # as a series of dates.
    if (!$Escaped) {
        for(
            $day = $cal.SelectionRange.Start;
            $day -le $cal.SelectionRange.End;
            $day = $day.AddDays(1)
            )
        {
            $day
        }
    }

    # 2009-08-27
    # -initialized $Escaped and removed $ShowTodayCircle (thanks, tojo2000) 
    # -modified $FirstDayOfWeek so casts don't occur until after Forms library loaded.
}

## http://rubli.info/t-blog/2011/06/29/querying-key-states-in-powershell/
Function Get-KeyState {
    param(
        [UInt16]$KeyCode
    )

    $Signature = '[DllImport("user32.dll")]public static extern short GetKeyState(int nVirtKey);'
    $Type = Add-Type -MemberDefinition $Signature -Name User32PowerTab -Namespace GetKeyState -PassThru
    return [Bool]($Type::GetKeyState($KeyCode) -band 0x80)
}

Function Write-Trace {
    param(
        [String]$message = "Entering function."  ## TODO: localize
    )

    if ($PowerTabLog.TraceEnabled) {
        $TraceEntry = New-Object PSObject -Property @{
            TraceId = $TraceId
            Time = Get-Date
            Location = @(Get-PSCallStack)[1]
            Message = $Message
        }
        $TraceEntry.PSObject.TypeNames.Insert(0, ”PowerTab.TraceEntry”)

        $PowerTabLog.Trace.Insert(0, $TraceEntry)
    }
}

## Modified slightly for specific use in PowerTab
function Get-FileEncoding {
<#
.SYNOPSIS
Gets file encoding.
.DESCRIPTION
The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
This command gets ps1 files in current directory where encoding is not ASCII
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
Same as previous example but fixes encoding using set-content
.NOTES
Version History
v1.0   - 2010/08/10, Chad Miller - Initial release
v1.1   - 2010/08/16, Jason Archer - Improved pipeline support and added detection of little endian BOMs.
#>
    [CmdletBinding()]
    param (
        [Alias("PSPath")]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]$Path
    )

    process {
        $Encoding = "ASCII"
        [Byte[]]$byte = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -Path $Path -ErrorAction SilentlyContinue

        if ($byte) {
            if ($byte[0] -eq 0xEF -and $byte[1] -eq 0xBB -and $byte[2] -eq 0xBF) {
                $Encoding = "UTF8"
            } elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xFE -and $byte[3] -eq 0xFF) {
                ## UTF-32 Big-Endian
                $Encoding = "BigEndianUnicode"
            } elseif ($byte[0] -eq 0xFF -and $byte[1] -eq 0xFE -and $byte[2] -eq 0 -and $byte[3] -eq 0) {
                ## UTF-32 Little-Endian
                $Encoding = "Unicode"
            } elseif ($byte[0] -eq 0xFE -and $byte[1] -eq 0xFF) {
                ## 1201 UTF-16 Big-Endian
                $Encoding = "BigEndianUnicode"
            } elseif ($byte[0] -eq 0xFF -and $byte[1] -eq 0xFE) {
                ## 1200 UTF-16 Little-Endian
                $Encoding = "Unicode"
            } elseif ($byte[0] -eq 0x2B -and $byte[1] -eq 0x2F -and $byte[2] -eq 0x76) {
                $Encoding = "UTF7"
            }
        }

        $Encoding
    }
}

############

Function Test-IsolatedStoragePath {
    [CmdletBinding()]
    param(
        [Alias("LiteralPath")]
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path
    )

    process {
        try {
            $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
            if ($UserIsoStorage.GetFileNames($Path)) {
                $true
            } else {
                $false
            }
        } catch {
            $false
        }
    }
}

Function Open-IsolatedStorageFile {
    [CmdletBinding()]
    param(
        [Alias("Path")]
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath
        ,
        [Switch]
        $Writable
    )

    process {
        if ($Writable) {
            $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
            if (Test-IsolatedStoragePath $LiteralPath) {
                New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream($LiteralPath, [System.IO.FileMode]::Truncate, $UserIsoStorage)
            } else {
                New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream($LiteralPath, [System.IO.FileMode]::Create, $UserIsoStorage)
            }
        } else {
            $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
            New-Object System.IO.IsolatedStorage.IsolatedStorageFileStream($LiteralPath, [System.IO.FileMode]::Open, $UserIsoStorage)
        }
    }
}

Function New-IsolatedStorageDirectory {
    [CmdletBinding()]
    param(
        [Alias("Path")]
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $LiteralPath
    )

    process {
        $UserIsoStorage = [System.IO.IsolatedStorage.IsolatedStorageFile]::GetUserStoreForAssembly()
        if (-not $UserIsoStorage.GetDirectoryNames($LiteralPath)) {$UserIsoStorage.CreateDirectory($LiteralPath)}
    }
}

Function Get-IsolatedStorage {
}


##########
# Here there be hacks (from Jaykul)
##########

Function Parse-Manifest {
    $Manifest = Get-Content "$PSScriptRoot\PowerTab.psd1" | Where-Object {$_ -notmatch '^\s*#'}
    $ModuleManifest = "Data {`n" + ($Manifest -join "`r`n") + "`n}"
    $ExecutionContext.SessionState.InvokeCommand.NewScriptBlock($ModuleManifest).Invoke()[0]
}

Function Find-Module {
    [CmdletBinding()]
    param(
        [String[]]$Name = "*"
        ,
        [Switch]$All
    )

    foreach ($n in $Name) {
        $folder = [System.IO.Path]::GetDirectoryName($n)
        $n = [System.IO.Path]::GetFileName($n)
        $ModulePaths = Get-ModulePath

        if ($folder) {
            $ModulePaths = Join-Path $ModulePaths $folder
        }

        ## Note: the order of these is important. They need to be in the order they'd be loaded by the system
        $Files = @(Get-ChildItem -Path $ModulePaths -Recurse -Filter "$n.ps?1" -EA 0; Get-ChildItem -Path $ModulePaths -Recurse -Filter "$n.dll" -EA 0)
        $Files | Where-Object {
                $parent = [System.IO.Path]::GetFileName( $_.PSParentPath )
                return $all -or ($parent -eq $_.BaseName) -or ($folder -and ($parent -eq ([System.IO.Path]::GetFileName($folder))) -and ($n -eq $_.BaseName))
            } | Group-Object PSParentPath | ForEach-Object {@($_.Group)[0]}
    }
}

# | Sort-Object {switch ($_.Extension) {".psd1"{1} ".psm1"{2}}})
Function Get-ModulePath {
    $Env:PSModulePath -split ";" | ForEach-Object {"{0}\" -f $_.TrimEnd('\','/')} | Select-Object -Unique | Where-Object {Test-Path $_}
}