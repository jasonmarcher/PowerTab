# TabExpansionCore.ps1
#
# 


# .ExternalHelp TabExpansionCore-Help.xml
Function Invoke-TabExpansion {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $Line
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $LastWord
        ,
        [Switch]
        $ForceList
    )

    $null = [System.Management.Automation.PSParser]::Tokenize('', [ref]$null)
    $Errors = New-Object System.Collections.ObjectModel.Collection``1[System.Management.Automation.PSParseError]
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($Line, [ref]$Errors)

    ## Figure out the context of this tab expansion request
    $_TokenTypes = [System.Management.Automation.PSTokenType]
    $ScopeStack = New-Object System.Collections.Stack
    $CurrentContext = New-TabContext
    $LastToken = $null
    $LastParameter = ""
    ## TODO: Save all values from a list for a parameter
    foreach ($Token in $Tokens) {
        if (($Token.Type -eq $_TokenTypes::Command) -and !($CurrentContext.Command)) {
            $CurrentContext.Command = try {Resolve-Command $Token.Content -ErrorAction "Stop"} catch {$Token.Content}
            $CurrentContext.isCommandMode = $true
        } elseif (($Token.Type -eq $_TokenTypes::Keyword) -and !($CurrentContext.Command) -and
                (@("function") -contains $Token.Content)) {
            $CurrentContext.Command = $Token.Content
            $CurrentContext.isCommandMode = $true
        } elseif ($Token.Type -eq $_TokenTypes::CommandParameter) {
            if ($CurrentContext.Parameter) {
                $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $CurrentContext.Argument
            } elseif ($CurrentContext.Argument) {
                while ($CurrentContext.PositionalParameters.Count -le $CurrentContext.PositionalParameter) {
                    $CurrentContext.PositionalParameters += @("")
                }
                $CurrentContext.PositionalParameters[$CurrentContext.PositionalParameter] = $CurrentContext.Argument
            }
            $CurrentContext.Parameter = try {
                if ($TabExpansionCommandInfoRegistry[$CurrentContext.Command]) {
                    $ScriptBlock = $TabExpansionCommandInfoRegistry[$CurrentContext.Command]
                    $CommandInfo = & $ScriptBlock $CurrentContext
                    if ($CommandInfo) {
                        Resolve-Parameter $CommandInfo $Token.Content
                    } else {
                        Resolve-Parameter $CurrentContext.Command $Token.Content
                    }
                } else {
                    Resolve-Parameter $CurrentContext.Command $Token.Content
                }
            } catch {$Token.Content -replace '^-'}
            if (-not $CurrentContext.Parameter) {$CurrentContext.Parameter = $Token.Content -replace '^-'}
            $CurrentContext.Argument = ""
            $CurrentContext.isParameterValue = $false

            ## Check if parameter is a switch
            try {
                if ($TabExpansionCommandInfoRegistry[$CurrentContext.Command]) {
                    $ScriptBlock = $TabExpansionCommandInfoRegistry[$CurrentContext.Command]
                    $CommandInfo = & $ScriptBlock $CurrentContext
                    if ($CommandInfo) {
                        $Parameter = Resolve-Parameter $CommandInfo $CurrentContext.Parameter -ParameterInfo
                    } else {
                        ## TODO:
                        throw "foo"
                    }
                } else {
                    $Parameter = Resolve-Parameter $CurrentContext.Command $CurrentContext.Parameter -ParameterInfo
                }
                if ($Parameter.ParameterType -eq [System.Management.Automation.SwitchParameter]) {
                    $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $true
                    $CurrentContext.Parameter = ""
                    $CurrentContext.Argument = ""
                    $CurrentContext.isParameterValue = $false
                }
            } catch {}
        } elseif (($Token.Type -eq $_TokenTypes::StatementSeparator) -or ($Token.Content -eq "|")) {
            $CurrentContext = New-TabContext
        } elseif (($Token.Type -eq $_TokenTypes::Operator) -and ($Token.Content -eq "=")) {
            $CurrentContext.isAssignment = $true
        } elseif ($CurrentContext.isCommandMode -and (($_TokenTypes::CommandArgument, $_TokenTypes::Member,
                $_TokenTypes::Number, $_TokenTypes::Operator, $_TokenTypes::String, $_TokenTypes::Variable) -contains $Token.Type)) {
            if (($Token.Type -eq $_TokenTypes::Operator) -and ("," -eq $Token.Content)) {
                ## TODO: Keep track of full list of values for a parameter?
            }

            if ($LastToken.EndColumn -ne $Token.StartColumn) {
                if ((-not $Token.Content.StartsWith("-")) -and $CurrentContext.Argument -ne "") {
                    if ($CurrentContext.Parameter) {
                        $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $CurrentContext.Argument
                    } elseif ($CurrentContext.Argument) {
                        while ($CurrentContext.PositionalParameters.Count -le $CurrentContext.PositionalParameter) {
                            $CurrentContext.PositionalParameters += @("")
                        }
                        $CurrentContext.PositionalParameters[$CurrentContext.PositionalParameter] = $CurrentContext.Argument
                    }
                    ## Found value for positional parameter
                    $CurrentContext.Parameter = ""
                    $CurrentContext.Argument = ""
                    $CurrentContext.PositionalParameter += 1
                    $CurrentContext.isParameterValue = $true
                } elseif ($Token.Content.StartsWith("-")) {
                    if ($CurrentContext.Parameter) {
                        $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $CurrentContext.Argument
                    } elseif ($CurrentContext.Argument) {
                        while ($CurrentContext.PositionalParameters.Count -le $CurrentContext.PositionalParameter) {
                            $CurrentContext.PositionalParameters += @("")
                        }
                        $CurrentContext.PositionalParameters[$CurrentContext.PositionalParameter] = $CurrentContext.Argument
                    }
                    $CurrentContext.Parameter = ""
                    $CurrentContext.Argument = ""
                    $CurrentContext.isParameterValue = $false
                    continue
                }
            }

            ## Decide if this token could be handed off to parameter tab completion
            if (($_TokenTypes::CommandArgument, $_TokenTypes::Number, $_TokenTypes::String) -contains $Token.Type) {
                $CurrentContext.Argument = $Token.Content
                $CurrentContext.isParameterValue = $true
            } elseif ($Token.Type -eq $_TokenTypes::Variable) {
                $CurrentContext.Argument = '$' + $Token.Content
                $CurrentContext.isParameterValue = $true
            } elseif (($Token.Type -eq $_TokenTypes::Operator) -and ("," -eq $Token.Content)) {
                $CurrentContext.Argument = ""
                $CurrentContext.isParameterValue = $true
            } else {
                $CurrentContext.Argument = ""
                $CurrentContext.isParameterValue = $false
            }
        } elseif ($Token.Type -eq $_TokenTypes::GroupStart) {
            $ScopeStack.Push($CurrentContext)
            $CurrentContext = New-TabContext
        } elseif ($Token.Type -eq $_TokenTypes::GroupEnd) {
            $CurrentContext = $ScopeStack.Pop()
            if ($CurrentContext.Parameter) {
                $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $CurrentContext.Argument
            }
            $CurrentContext.Parameter = ""
            $CurrentContext.Argument = ""
            $CurrentContext.isParameterValue = $false
        }

        $LastToken = $Token
    }
    ## Special case, last word is "@", this causes a parsing error so we don't see the token
    if ($LastWord -eq '@') {
        if (-not $CurrentContext.Parameter) {
            $CurrentContext.PositionalParameter += 1
        }
        $CurrentContext.Argument = $LastWord
        $CurrentContext.isParameterValue = $true
    }
    ## Special case, blank value for parameter
    if (-not $LastWord) {
        if ($LastToken.Content -eq ",") {
            ## Don't do anything, build on existing list
        } elseif ($CurrentContext.Argument -ne $LastWord) {
            ## Special case, blank value for positional parameter after another parameter (foo -bar "test" _)
            if ($CurrentContext.Parameter) {
                $CurrentContext.OtherParameters[$CurrentContext.Parameter] = $CurrentContext.Argument
                $CurrentContext.Parameter = ""
            } elseif ($CurrentContext.Argument) {
                while ($CurrentContext.PositionalParameters.Count -le $CurrentContext.PositionalParameter) {
                    $CurrentContext.PositionalParameters += @("")
                }
                $CurrentContext.PositionalParameters[$CurrentContext.PositionalParameter] = $CurrentContext.Argument
            }
            if ($CurrentContext.Command) {
                $CurrentContext.PositionalParameter += 1
            }
        } else {
            if (-not $CurrentContext.Parameter) {
                $CurrentContext.PositionalParameter += 1
            }
        }

        if ($CurrentContext.Command) {
            $CurrentContext.Argument = ""
            $CurrentContext.isParameterValue = $true
        }
    }

    ## Resolve name of positional parameter
    if ((-not $CurrentContext.Parameter) -and ($LastWord -ne "-")) {
        try {
            $CurrentContext = Resolve-PositionalParameter $CurrentContext
        } catch {}
    }

    ## Add additional context information
    Add-Member -InputObject $CurrentContext -Name Line -Value $Line -MemberType NoteProperty
    Add-Member -InputObject $CurrentContext -Name LastWord -Value $LastWord -MemberType NoteProperty
    Add-Member -InputObject $CurrentContext -Name LastToken -Value $LastToken.Type -MemberType NoteProperty
    ##  Special debug logging
    if ($PowerTabLog) {
        $CurrentContext | Select-Object Line,LastWord,LastToken,Command,Parameter,Argument,PositionalParameter,
            PositionalParameters,OtherParameters,isCommandMode,isAssignment,isParameterValue | Out-String |
            Add-Content (Join-Path $env:USERPROFILE "PowerTab.log")
    }

    ## Indicate we are busy
    Invoke-TabActivityIndicator

    try {
        ## Detect DoubleTab if enabled
        if ($PowerTabConfig.DoubleTabEnabled) {
            Start-Sleep -m 400
            $DoubleTab = ($Host.UI.RawUI.KeyAvailable)
        } else {
            $DoubleTab = $PowerTabConfig.DoubleTabLock  
        }

        ## Check DoubleTab and set selection handler
        if ($DoubleTab) {
            $SelectionHandler = $PowerTabConfig.AlternateHandler
        } else {
            $SelectionHandler = $PowerTabConfig.DefaultHandler
        }

        ## Resolve internal (no prefix) and fully qualified command names
        $FullCommandName = ""
        try {
            $InternalCommand = Resolve-InternalCommandName $CurrentContext.Command
            $InternalCommandName = $InternalCommand.InternalName
            if ($InternalCommand.Module) {
                $FullCommandName = $InternalCommand.Module.Name + "\" + $InternalCommand.InternalName
            }
        } catch {
            $InternalCommandName = ""#$CurrentContext.Command
        }

        [Bool]$TabExpansionHasOutput = $false
        [Bool]$QuoteSpaces = $true
        $PossibleValues = @()
        if ($CurrentContext.isParameterValue) {
            ## Tab complete parameter value

            ## Command registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionCommandRegistry[$FullCommandName]) {
                $ScriptBlock = $TabExpansionCommandRegistry[$FullCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }
            if ((-not $TabExpansionHasOutput) -and $TabExpansionCommandRegistry[$InternalCommandName]) {
                $ScriptBlock = $TabExpansionCommandRegistry[$InternalCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }

            ## Parameter registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterRegistry[$CurrentContext.Parameter]) {
                $ScriptBlock = $TabExpansionParameterRegistry[$CurrentContext.Parameter]
                $PossibleValues = & $ScriptBlock $CurrentContext.Argument ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }

            ## Enum and ValidateSet() support
            if (-not $TabExpansionHasOutput) {
                try {
                    ## Get parameter info
                    if ($TabExpansionCommandInfoRegistry[$InternalCommandName]) {
                        $ScriptBlock = $TabExpansionCommandInfoRegistry[$InternalCommandName]
                        $CommandInfo = & $ScriptBlock $CurrentContext
                        if ($CommandInfo) {
                            $ParameterInfo = Resolve-Parameter $CommandInfo $CurrentContext.Parameter -ParameterInfo
                        } else {
                            $ParameterInfo = Resolve-Parameter $CurrentContext.Command $CurrentContext.Parameter -ParameterInfo
                        }
                    } else {
                        $ParameterInfo = Resolve-Parameter $CurrentContext.Command $CurrentContext.Parameter -ParameterInfo
                    }

                    ## Enum
                    if ($ParameterInfo.ParameterType.BaseType -eq [System.Enum]) {
                        $TabExpansionHasOutput = $true
                        $PossibleValues = [Enum]::GetNames($ParameterInfo.ParameterType) | Where-Object {$_ -like ($CurrentContext.Argument + "*")}
                    }

                    ## ValidateSet
                    if (-not $TabExpansionHasOutput) {
                        $ValidateSet = $ParameterInfo.Attributes | Where-Object {$_ -is [System.Management.Automation.ValidateSetAttribute]}
                        if ($ValidateSet) {
                            $TabExpansionHasOutput = $true
                            $PossibleValues = $ValidateSet | Select-Object -ExpandProperty ValidValues | Where-Object {$_ -like ($CurrentContext.Argument + "*")}
                        }
                    }
                } catch {}
            }

            ## Ensure that variables get handled
            if ($PossibleValues -eq $null) {$PossibleValues = @()}
            if ($TabExpansionHasOutput -and ($PossibleValues.Count -eq 0) -and ($LastWord -match '^[@\$]')) {
                $TabExpansionHasOutput = $false
            }
        } elseif (($LastWord -match "^-") -and $CurrentContext.isCommandMode) {
            ## Tab complete parameter name

            ## Parameter name registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterNameRegistry[$FullCommandName]) {
                $ScriptBlock = $TabExpansionParameterNameRegistry[$FullCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext $LastWord
                if ($PossibleValues) {
                    $TabExpansionHasOutput = $true
                }
            }
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterNameRegistry[$InternalCommandName]) {
                $ScriptBlock = $TabExpansionParameterNameRegistry[$InternalCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext $LastWord
                if ($PossibleValues) {
                    $TabExpansionHasOutput = $true
                }
            }

            ## Command info
            if (-not $TabExpansionHasOutput) {
                try {
                    $CommandInfo = Resolve-Command $CurrentContext.Command -CommandInfo
                    $Parameter = $LastWord -replace "^-"
                    $PossibleValues = $CommandInfo.Parameters.Values | Where-Object {$_.Name -like "$Parameter*"} | ForEach-Object {"-" + $_.Name}
                    $TabExpansionHasOutput = $true
                } catch {}
            }
        } elseif ($LastToken.Type -eq $_TokenTypes::GroupStart) {
            ## Tab complete method signatures
            $MethodTokens = @([System.Management.Automation.PSParser]::Tokenize($LastWord, [ref]$Errors))
            if ($MethodTokens[-2].Type -eq $_TokenTypes::Member) {
                $MethodObject = $LastWord.SubString(0, $MethodTokens[-1].Start)
                $PossibleValues = Invoke-Expression "$MethodObject.OverloadDefinitions" | ForEach-Object {
                    $Parameters = $_ -replace '^\S+ .+\((.+)?\)','$1'
                    if ($Parameters) {
                        $Parameters = foreach ($Parameter in ($Parameters -split ", ")) {
                            $Type = ($Parameter -split " ")[0]
                            $Name = ($Parameter -split " ")[1]
                            '[{0}] ${1}' -f $Type,$Name
                        }
                        $Parameters = $Parameters -join ", "
                    }
                    "{0}{1})" -f $LastWord,$Parameters
                }
                $TabExpansionHasOutput = $true
            }
        }

        if ($TabExpansionHasOutput) {
            $PossibleValues | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler | ForEach-Object {
                if ($_ -is [String]) {
                    if ($QuoteSpaces -and ($_ -match " ") -and ($_ -notmatch "^[`"'].*[`"']`$") -and
                        (($LastToken.Type -eq $_TokenTypes::CommandArgument) -or ($LastWord -eq ""))) {
                        '"' + $_ + '"'
                    } else {
                        $_
                    }
                } else {
                    if ($QuoteSpaces -and ($_.Value -match " ") -and ($_.Value -notmatch "^[`"'].*[`"']`$") -and
                        (($LastToken.Type -eq $_TokenTypes::CommandArgument) -or ($LastWord -eq ""))) {
                        $_.Value = '"' + $_.Value + '"'
                    } else {
                        $_
                    }
                }
            }
            if ($PossibleValues.Count -lt 1) {
                ## No values
                if ($LastWord) {
                    ## Return what the user typed
                    $LastWord
                } else {
                    ## Send blank to prevent default PowerShell tab expansion
                    ""
                }
            }
        } else {
            Invoke-PowerTab -Line $Line -LastWord $LastWord -Context $CurrentContext -ForceList:$ForceList
        }
    } catch {
        Invoke-TabActivityIndicator -Error
        ""
    } finally {
        ## Remove busy indication on ready or error
        Remove-TabActivityIndicator
    }
}

Function New-TabContext {
    $Properties = @{
            "Command" = ""
            "Parameter" = ""
            "Argument" = $null
            "ArgumentList" = @()
            "PositionalParameter" = -1
            "PositionalParameters" = @()
            "OtherParameters" = @{}
            "isCommandMode" = $false
            "isAssignment" = $false
            "isParameterValue" = $false
        }
    New-Object PSObject -Property $Properties
}


Function Invoke-PowerTab {
    param(
        $Line,
        $LastWord,
        $Context,
        [Switch]$ForceList
    ) 

    &{
    $TabExpansionHasOutput = $false

    if ($PowerTabConfig.IgnoreConfirmPreference) {
        $OriginalConfirmPreference = $ConfirmPreference
        $ConfirmPreference = 'High'
    }

    ## Helper variables 
    $_Method = [System.Management.Automation.PSMemberTypes]'Method,CodeMethod,ScriptMethod,ParameterizedProperty'
    $_ScopeNames = @("global", "local", "script", "private")

    ## Parse commandline
    $LineBlocks = [Regex]::Split($Line, '[|;]')
    $LastBlock = $LineBlocks[-1]

    ## Helper Functions
    Function Resolve-Member {
        param(
            $Object,
            $Pattern
        )

        ## Check for multilevel members
        $LevelCount = $Pattern.Split('.').Count
        if ($LevelCount -gt 1) { 
            $OFS = '.'; $Object += ".$($Pattern.Split('.')[0..($LevelCount -2)])"
        }

        ## Resolve Members
        $val = $Object
        $pat = $Pattern.Split('.')[($Level -1)] + '*'
        . {
            if ('PSBase' -like $pat) {$val + '.PSBase'}
            Invoke-Expression "Get-Member -InputObject ($val)" | Where-Object {
                $n = $_.Name
                if (-not $PowerTabConfig.ShowAccessorMethods) {
                    $n -like $pat -and $n -notmatch '^[gs]et_'
                } else {
                    $n -like $pat
                }
            } | ForEach-Object {
                if ($_.MemberType -band $_Method) {
                    ## Return a method...
                    $val + '.' + $_.Name + '('
                } else {
                    ## Return a property...
                    $val + '.' + $_.Name
                }
            }
        }
    }

    Function QuoteVariable {
        param(
            [String]$Name
        )

        ## Escape certain characters
        $Name = $Name -replace '([{}`])','`$1'

        ## If a variable name contains any of these characters it needs to be in braces
        $_varsRequiringQuotes = ('-`&@''#{}()$,;|<> .\/' + "`t").ToCharArray()
        if ($Name.IndexOfAny($_varsRequiringQuotes) -ge -0) {
            "{$Name}"
        } else {
            $Name
        }
    }

    &{
        ## Main tabcompletion , check line for patterns, select completion method and invoke handler

        ## Evaluate last block
        switch -regex ($LastBlock)  {
            ## Handle multilevel property and method expansion on simple () Blocks
            '(^| )\((.+)\)\.(.*)' {
                &{ trap {continue}
                    Resolve-Member -Object "($($Matches[2]))" -Pattern $Matches[3] |
                        Invoke-TabItemSelector $LastBlock -SelectionHandler $SelectionHandler | ForEach-Object {
                            $TabExpansionHasOutput = $true
                            if ($_.IndexOf(' ') -ge 0 ) {
                                ([Regex]::Split($_,' '))[-1].Trim()
                            } else {
                                $_
                            }
                        }
                }
                if ($TabExpansionHasOutput) {
                    ## Tab expansion handled, don't do anything more
                    return
                }
            }
        }

        ## Evaluate last word 
        switch -regex ($LastWord)  {
            ## Handle inline type search, e.g. new-object .identityreference<tab> or .identityre<tab> (oisin) 
            '^(\[*?)\.(\w+)$' {
                $TypeName = $Matches[2]
                Get-TabExpansion "%.${TypeName}%" "Types" | Select-Object -ExpandProperty Name |
                    Invoke-TabItemSelector $LastWord.Replace('[', '') -SelectionHandler $SelectionHandler |
                    ForEach-Object {if ($Matches[1] -eq '[') {"[$_]"}}
                break
            }

            ## Members of script block
            '(.*\})\.([^\.]*)$' {
                $ScriptBlock = $Matches[1]
                $Member = $Matches[2]
                {} | Get-Member | Where-Object {
                    $n = $_.Name
                    if (-not $PowerTabConfig.ShowAccessorMethods) {
                        $n -like "$Member*" -and $n -notmatch '^[gs]et_'
                    } else {
                        $n -like "$Member*"
                    }
                } | ForEach-Object {
                    if ($_.MemberType -band $_Method) {
                        ## Return a method...
                        $ScriptBlock + '.' + $_.Name + '('
                    } else {
                        ## Return a property...
                        $ScriptBlock + '.' + $_.Name
                    }
                } | Invoke-TabItemSelector "$ScriptBlock.$Member" -SelectionHandler $SelectionHandler
                break
            }

            ## Completion on Shares (commented lines without DLL but need admin rights )
            '^\\\\([^\\]+)\\([^\\]*)$' {
                #gwmi win32_share -computer $matches[1] -filter "name like '$($matches[2])%'" | Foreach-Object {"\\$($matches[1])\$($_.name)"}
                #([adsi]"WinNT://$($matches[1])/LanmanServer,FileService" ).psbase.children |? {$_.name -like "$($matches[2])*"}  |% {$_.name}
                [Trinet.Networking.ShareCollection]::GetShares($Matches[1]) | Where-Object {$_.NetName -like "$($Matches[2])*"} |
                    Sort-Object NetName | ForEach-Object {"\\$($Matches[1])\$($_.NetName)"} |
                    Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Completion on computers in database
            '^\\\\([^\\]*)$' {
                Get-TabExpansion "$($Matches[1])*" "Computer" |
                    ForEach-Object {"\\$($_.Text)"} | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Variable "In-Place" expansion on \[tab]
            '.*(\$[^\\]+)\\$' {
                $val = $ExecutionContext.InvokeCommand.ExpandString($Matches[1])
                ($Matches[0] -replace ([Regex]::Escape($Matches[1])), $val).TrimEnd('\')
                break
            }

            ## Replace <command>-? with call to Get-Help
            '.*\-\?' {"Get-Help " + $LastWord.Replace('-?', ' -')}

            ## PSDrive expansion on :[tab]
            '^:$' {Get-PSDrive | ForEach-Object {$_.Name + ':'} | Invoke-TabItemSelector '' -SelectionHandler $SelectionHandler}

            ## History completion against either #<pattern> or #<id>
            '^#(\w*)' {
                $Pattern = $Matches[1]
                if ($Pattern -match '^[0-9]+$') {
                    Get-History -Id $Pattern -ErrorAction SilentlyContinue | ForEach-Object {$_.CommandLine}
                } else {
                    Get-History -Count 32767 | Where-Object {$_.CommandLine -like "$Pattern*"} | Sort-Object -Descending Id |
                        ForEach-Object {$_.CommandLine} | Invoke-TabItemSelector $Pattern -SelectionHandler $SelectionHandler
                }
                break
            }

            ## About Topics completion
            'about_(.*)' {
                Get-Help "about_$($Matches[1])*" | ForEach-Object {$_.Name} |
                    Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## DataGrid GUI Shortcuts
            '^a_(.*)' {Get-Help "about_$($Matches[1])*" | Select-Object Name,Synopsis,Length | Out-DataGridView Name | Foreach-Object {Get-Help $_}}
            '^w_(.*)' {Get-TabExpansion "win32_$($Matches[1])*" "WMI" | Select-Object "Name" | Out-DataGridView Name}
            '^t_(.*)' {Get-TabExpansion "*$($Matches[1])*" "Types" | Select-Object "Name" | Out-DataGridView Name}
            '^c_(.*)' {Get-TabExpansion "$($Matches[1])*" | Select-Object "Text" | Out-DataGridView Text}
            '^f_' {Get-ChildItem function: | Select-Object Name | Out-DataGridView Name}
            '^d_' {Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name,FullName | Out-DataGridView FullName}
            '^h_' {Get-History -Count 100 | Out-DataGridView Commandline}

            ## WMI completion
            '(win32_.*|cim_.*|MSFT_.*)' {
                Get-TabExpansion "$($Matches[1])*" "WMI" | Select-Object -ExpandProperty Name |
                    Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Handle property and method expansion on variables
            '\$(.+)\.(.*)' {
                Resolve-Member -Object ('$' + $Matches[1]) -Pattern $Matches[2] |
                    Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Translate typename to New-Object statement  [String][tab]
            '(\[.*\])=(\w*)' {
                "New-Object $($Matches[1].Replace('[','').Replace(']',''))"
                break
            }

            ## Handle Static methods of Types
            '(\[.*\])::(.*)$' { 
                $LastType = $Matches[1]
                $Level = $Matches[2].Split('.').Count

                if ($Level -gt 1) {
                    $LastType += ('::' + $Matches[2].Split('.')[0])
                    $Pattern = $Matches[2].SubString(($Matches[2].IndexOf('.') + 1))
                    Resolve-Member -Object $LastType -Pattern $Pattern | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                } else {
                    $Pattern = $Matches[2].Split('.')[($Level -1)] + '*'
                    Invoke-Expression "$($Matches[1]) | Get-Member -Static" | Where-Object {
                        $n = $_.Name; $n -like $Pattern -and $n -notmatch '^[ge]et_'} | ForEach-Object {
                            if ($_.MemberType -band $_Method) {
                                "${LastType}::$($_.Name)" + '('
                            } else {
                                "${LastType}::$($_.Name)"
                            }
                        } | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                }
                break
            }

            ## Handle Static methods of types in Variables
            '(\$.*)::(.*)$' {
                $LastType = $Matches[1]
                $Level = $Matches[2].Split('.').Count
                $gt = ''

                if ((Invoke-Expression "$LastType.GetType().Name") -ne 'RuntimeType') {$gt = '.GetType'}
                if ($Level -gt 1) {
                    $LastType += ('::' + $Matches[2].Split('.')[0])
                    $Pattern = $Matches[2].SubString(($Matches[2].IndexOf('.') + 1))
                    Resolve-Member -Object $LastType -Pattern $Pattern | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                } else {
                    $Pattern = $Matches[2].Split('.')[($Level -1)] + '*'
                    Invoke-Expression "$($Matches[1]) | Get-Member -Static" | Where-Object {
                        $n = $_.Name; $n -like $Pattern -and $n -notmatch '^[ge]et_'} | ForEach-Object {
                            if ($_.MemberType -band $_Method) {
                                "${LastType}${gt}::$($_.Name)" + '('
                            } else {
                                "${LastType}${gt}::$($_.Name)"
                            }
                        } | Invoke-TabItemSelector $LastWord.Replace('::',"${gt}::") -SelectionHandler $SelectionHandler
                }
                break
            }

            ## Handle enums and Constructors of Types
            '(\[.*\]):*$' {
                $LastType = $Matches[1].Split(',')[-1]
                $BaseType = (Invoke-Expression "$LastType.BaseType.FullName")
                . {
                    if ($BaseType -eq 'System.Enum') {
                        $Names = Invoke-Expression "[Enum]::GetNames($LastType)" | ForEach-Object {"${LastType}::$_"} |
                            Invoke-TabItemSelector ($LastType + '::') -SelectionHandler $SelectionHandler
                    } else {
                        $Constructors = Invoke-Expression "$LastType.GetConstructors()" | ForEach-Object {
                            $Regex = New-Object Regex('\((.*)\)')
                            $ParamTypes = $Regex.Match($_).Groups[1].Value.Split(',') | ForEach-Object {"[$($_.Trim())]"}
                            $Param = [String]::Join(' , ',$ParamTypes)
                            "New-Object $($LastType.Trim('[]'))($Param)".Replace('([])','()')
                        }
                        if ($Constructors) {
                            $Constructors | Invoke-TabItemSelector $LastType -SelectionHandler $SelectionHandler
                        } else {
                            $LastWord
                        }
                    }
                }
                break
            }

            ## Handle members of Types (runtype)
            '^(\[.*\]).(\w*)$' {
                $LastType = $Matches[1].Split(',')[-1]
                Invoke-Expression "$LastType | Get-Member" | Where-Object {$_.Name -like "$($Matches[2])*"} | ForEach-Object {
                    if ($_.MemberType -band $_Method) {
                        "$LastType.$($_.Name)" + '('
                    } else {
                        "$LastType.$($_.Name)"
                    }
                } | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            } 

            ## Handle namespace and type names 
            '^\[(.*)$' {
                $Matched = $Matches[1]
                $Dots = $Matches[1].Split(".").Count - 1
                $res = @()
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("ns like '$($Matched)%' and dc = $($Dots + 1)") |
                    Select-Object -Unique ns | ForEach-Object {"[$($_.ns)"}
                if ($Dots -gt 0) {
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like '$($Matched)%' and dc = $Dots") | ForEach-Object {"[$($_.Name)]"}
                }
                $res | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler -ForceList:$ForceList
                break
            }

            ## Handle expansions for both "Scope Variable Name" and "Type Variable Names"
            '^\$(\w+):(\w*)$' {
                $Type = $Matches[1]     # function, variable, global, etc.
                $TypeName = $Matches[2] # e.g. in '$function:C', value will be 'C'

                if ($_ScopeNames -contains $Type) {
                    # Scope variable name expansion ($global:, $script:, etc.)
                    $Variables = foreach ($ScopeVariable in (Get-Variable "$TypeName*" -Scope $Type)) {
                        $Type + ":" + $ScopeVariable.Name
                    }
                } else {
                    # Type variable name expansion ($function:, $variable:, $env:, etc.)
                    $Variables = foreach ($t in (Get-ChildItem ($Type + ":" + $TypeName + '*') | Sort-Object Name)) {
                        $Type + ":" + $t.Name
                    }
                }
                $Variables | ForEach-Object {'$' + (QuoteVariable $_)} | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Handle variable name expansion
            '^([\$@])(\w*)$' {
                ## TODO: This could be simplified
                $VarName = $Matches[2]
                Get-Variable "$VarName*" -Scope Global | Select-Object -ExpandProperty Name |
                    ForEach-Object {$Matches[1] + (QuoteVariable $_)} | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Completion on cmdlets, function, aliases and native commands with defined shortcuts and custom additions from database

            ## Native commands / scripts in path
            "(.*)$([Regex]::Escape($PowerTabConfig.ShortcutChars.Native))`$" { 
                & {
                    Get-Command -CommandType ExternalScript -Name "$($Matches[1])*"
                    Get-Command -CommandType Application -Name "$($Matches[1])*" |
                        Where-Object {($env:PATHEXT).Split(";") -contains $_.Extension}
                } | Select-Object -ExpandProperty Name |
                    Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                break
            }

            ## Aliases
            "(.+)$([Regex]::Escape($PowerTabConfig.ShortcutChars.Alias))`$" {
                & {
                    Get-Command -CommandType Alias -Name $Matches[1] | Select-Object -ExpandProperty Definition
                    Get-TabExpansion $Matches[1] "Alias" | Select-Object -ExpandProperty Text
                } | Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                break
            }

            ## Custom
            "(.*)$([Regex]::Escape($PowerTabConfig.ShortcutChars.Custom))`$" {
                Get-TabExpansion "$($Matches[1])*" "Custom" | Select-Object -ExpandProperty Text |
                    Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                break
            }

            ## Invoke
            "(.+)$([Regex]::Escape($PowerTabConfig.ShortcutChars.Invoke))`$" {
                Get-TabExpansion "$($Matches[1])*" "Invoke" | ForEach-Object {
                    $ExecutionContext.InvokeCommand.InvokeScript($_.Text)
                } | Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                break
            }

            ## Call function
            "(.*)$([Regex]::Escape($PowerTabConfig.ShortcutChars.CustomFunction))`$" {
                if ($PowerTabConfig.CustomFunctionEnabled) {
                    $Matches[1] | ForEach-Object {
                        $ExecutionContext.InvokeCommand.InvokeScript("$($PowerTabConfig.CustomUserFunction) '$_'")
                    } | Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                }
                break
            }

            ## Partial functions or cmdlets
            "(.*)$([Regex]::Escape($PowerTabConfig.ShortcutChars.Partial))`$" {
                Get-Command -CommandType Function,Filter,Cmdlet -Name "$($Matches[1])*" | Select-Object -ExpandProperty Name |
                    Invoke-TabItemSelector $Matches[1] -SelectionHandler $SelectionHandler
                break
            }

            ## Functions or cmdlets on dash
            '(.+-.*)' {
                Get-Command -CommandType Function,ExternalScript,Filter,Cmdlet -Name "$($Matches[1])*" | Select-Object -ExpandProperty Name |
                    Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                break
            }

            ## Alternate alias
            '(.+)$' {
                if ($DoubleTab -or $PowerTabConfig.AliasQuickExpand) {
                    & {
                        Get-Command -CommandType Alias -Name $Matches[1] | Select-Object -ExpandProperty Definition
                        Get-TabExpansion $Matches[1] "Alias" | Select-Object -ExpandProperty Text
                    } | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
                } else {
                    Get-TabExpansion $Matches[1] "Alias" | Select-Object -ExpandProperty Text |
                        Invoke-TabItemSelector -SelectionHandler $SelectionHandler
                }
                break
            }
        } ## End of switch -regex $LastWord
    } | Where-Object {$_} | ForEach-Object {$TabExpansionHasOutput = $true; $_}

    ## Filesystem Completion
    if ((-not $TabExpansionHasOutput) -and $PowerTabConfig.FileSystemExpand) {
        $PowerTabFileSystemMode = $true

        if (("Push-Location","Set-Location") -contains $Context.Command) {
            $ChildItems = @(Get-ChildItem "$LastWord*" | Where-Object {$_.PSIsContainer})
        } else {
            $ChildItems = @(Get-ChildItem "$LastWord*")
        }
        if (-not $ChildItems) {$LastWord; return}

        #if ((@($childitems).count -eq 1) -and ($lastword.endswith('\')) ) {$childitems = $childitems,@{name='..'}}
        $PathSlices = [Regex]::Split($LastWord, '\\|/')
        if ($PathSlices.Count -eq 1) {$PathSlices = ,"." + $PathSlices}
        $Container = [String]::Join('\', $PathSlices[0..($PathSlices.Count -2)])

        $LastPath = $Container + "\$([Regex]::Split($LastWord,'\\|/|:')[-1])"

        $ChildItems | ForEach-Object {
            ## Improved fix for a problem identified by idvorkin (http://poshcode.org/1586)
            ## Fixes paths for registry keys and certificates
            $Item = $_
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
                "System.Management.Automation.FilterInfo" {"Filter";break}
                "System.Management.Automation.FunctionInfo" {"Function";break}
                "System.Security.Cryptography.X509Certificates.X509Certificate2" {"Certificate";break}
                "Microsoft.Powershell.Commands.X509StoreLocation" {"CertificateStore";break}
                "Microsoft.Win32.RegistryKey" {"RegistryKey";break}
                default {$_}
            }
            New-TabItem "$Container\$Child" "$Container\$Child" -Type $Type
        } | Invoke-TabItemSelector $LastPath -SelectionHandler $SelectionHandler -Return $LastWord -ForceList:$ForceList | ForEach-Object {
            if ($_ -is [String]) {
                $Quote = ''
                $Invoke = ''
                if (($_.IndexOf(' ') -ge 0) -and ($_.IndexOf('"') -lt 0) ) {
                    if (-not (@([Char[]]$LastBlock | Where-Object {$_ -match '"|'''}).Count % 2)) {$Quote = '"'}
                    if (($LastBlock.Trim() -eq $LastWord)) {$Invoke = '& '}
                }
                "$Invoke$Quote$_$Quote"
            } else {
                ## TODO: Implement quoting
                $_
            }
        }
    }

    } ## End of outer script block

    if ($PowerTabConfig.IgnoreConfirmPreference) {
        $ConfirmPreference = $OriginalConfirmPreference
    }

}  # end-function
