# TabExpansionCore.ps1
#
# 

## Reason: Intentional because we really need to suppress errors due to the nature of this module
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
## Reason: Intentional because we need to evaluate variables
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
## Reason: Script analyzer doesn't catch all variable usages
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

# .ExternalHelp TabExpansionCore-Help.xml
Function Invoke-TabExpansion {
    [CmdletBinding()]
    [OutputType([String])]
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

    try {
    if (-not $PSv3HasRun) {
        ## Hack to get around PS v3 submitting a tab expansion request on load
        $script:PSv3HasRun = $true
        if ($Line -eq "Set-Location" -and $LastWord -eq "Set-Location") {
            return $LastWord
        }
    }

    ## Indicate we are busy
    Invoke-TabActivityIndicator

    ## Generate new GUID if this is a new (ie non nested) tab expand execution
    if (-not $NestedPowerTab) {
        $TraceId = [System.Guid]::NewGuid()
    }
    Write-Trace "Entering PowerTab."

    ## Save global errors in the script scoped Error ( doesn't appear to be used )
    # This also addresses the problem of $Error[0].<TAB> not working since it uses the script scoped $Error as well.
    $script:Error.Clear()
    $script:Error.AddRange($global:Error)
    $global:Error.Clear()
    $global:Error.AddRange($PowerTabConfig.Log.Error)

    if ($null -eq $PowerTabConfig) {
        ## Something happened to the PowerTabConfig object, recreate it
        CreatePowerTabConfig
    }

    $ParseErrors = $null
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($Line, [ref]$ParseErrors)

    ## Figure out the context of this tab expansion request
    $_TokenTypes = [System.Management.Automation.PSTokenType]
    $ScopeStack = New-Object System.Collections.Stack
    $CurrentContext = New-TabContext
    $LastToken = $null
    $LastParameter = ""
    $OnNextToken = $null
    ## TODO: Save all values from a list for a parameter
    foreach ($Token in $Tokens) {
        if ($OnNextToken) {
            . $OnNextToken
            $OnNextToken = $null
        }

        if (($Token.Type -eq $_TokenTypes::Command) -and !($CurrentContext.Command)) {
            $CurrentContext.CommandInfo = try {Resolve-Command $Token.Content -CommandInfo -ErrorAction Stop} catch {}
            if ($CurrentContext.CommandInfo) {
                $CurrentContext.Command = $CurrentContext.CommandInfo.Name
            } else {
                $CurrentContext.Command = $Token.Content
            }
            $CurrentContext.isCommandMode = $true
            $CurrentContext.hasCommand = $true
        } elseif (($Token.Type -eq $_TokenTypes::Keyword) -and !($CurrentContext.Command) -and
                (@("function") -contains $Token.Content)) {
            $CurrentContext.Command = $Token.Content
            $CurrentContext.isCommandMode = $true
            $CurrentContext.hasCommand = $true
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
                        Resolve-Parameter $CurrentContext.CommandInfo $Token.Content
                    }
                } else {
                    Resolve-Parameter $CurrentContext.CommandInfo $Token.Content
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
                    $Parameter = Resolve-Parameter $CurrentContext.CommandInfo $CurrentContext.Parameter -ParameterInfo
                }
                if ($Parameter.ParameterType -eq [System.Management.Automation.SwitchParameter]) {
                    $ParameterName = $Parameter.Name
                    $OnNextToken = {$CurrentContext.OtherParameters[$ParameterName] = $true}.GetNewClosure()
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
                ## The parameter check is for the case of a switch appearing just befor a positional parameter:  Func -Switch tex<TAB>
                if ((-not $Token.Content.StartsWith("-")) -and (($CurrentContext.Argument -ne "") -or ($CurrentContext.Parameter -eq ""))) {
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
    ## but only in PS v2
    if (($LastWord -eq '@') -and ($PSVersionTable.PSVersion -eq "2.0")) {
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

    ## Save to history
    $PowerTabConfig.Log.History.Insert(0, ($CurrentContext | Select-Object @{n="TraceId";e={$TraceId}},Line,LastWord,LastToken,Command,Parameter,Argument,
        PositionalParameter,PositionalParameters,OtherParameters,hasCommand,isCommandMode,isAssignment,isParameterValue,CommandInfo))

    try {
        ## Detect DoubleTab if enabled
        if ($PowerTabConfig.Core.DoubleTabEnabled) {
            Start-Sleep -m 400
            $DoubleTab = ($Host.UI.RawUI.KeyAvailable)
        } else {
            $DoubleTab = $PowerTabConfig.Core.DoubleTabLock  
        }

        ## Check DoubleTab and set selection handler
        if ($DoubleTab) {
            $SelectionHandler = $PowerTabConfig.Core.AlternateHandler
        } else {
            $SelectionHandler = $PowerTabConfig.Core.DefaultHandler
        }

        ## Resolve internal (no prefix) and fully qualified command names
        $FullCommandName = ""
        try {
            if ($CurrentContext.CommandInfo) {
                $InternalCommand = Resolve-InternalCommandName $CurrentContext.CommandInfo
                $InternalCommandName = $InternalCommand.InternalName
                if ($InternalCommand.Module) {
                    $FullCommandName = $InternalCommand.Module.Name + "\" + $InternalCommand.InternalName
                }
            } else {
                $InternalCommandName = $CurrentContext.Command
            }
        } catch {
            $InternalCommandName = $CurrentContext.Command
        }

        [Bool]$TabExpansionHasOutput = $false
        [Bool]$QuoteSpaces = $true
        [Object[]]$PossibleValues = @()
        if ($CurrentContext.isParameterValue) {
            ## Tab complete parameter value

            ## Command registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionCommandRegistry[$FullCommandName]) {
                Write-Trace "Found entry in Command registry for FullCommandName."

                $ScriptBlock = $TabExpansionCommandRegistry[$FullCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }
            if ((-not $TabExpansionHasOutput) -and $TabExpansionCommandRegistry[$InternalCommandName]) {
                Write-Trace "Found entry in Command registry for InternalCommandName."

                $ScriptBlock = $TabExpansionCommandRegistry[$InternalCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }

            ## Parameter registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterRegistry[$CurrentContext.Parameter]) {
                Write-Trace "Found entry in Parameter registry."

                $ScriptBlock = $TabExpansionParameterRegistry[$CurrentContext.Parameter]
                $PossibleValues = & $ScriptBlock $CurrentContext.Argument ([ref]$TabExpansionHasOutput) ([ref]$QuoteSpaces)
            }

            ## Enum and ValidateSet() support
            if (-not $TabExpansionHasOutput) {
                try {
                    ## Get parameter info
                    if ($TabExpansionCommandInfoRegistry[$InternalCommandName]) {
                        Write-Trace "Found entry in CommandInfo registry."

                        $ScriptBlock = $TabExpansionCommandInfoRegistry[$InternalCommandName]
                        $CommandInfo = & $ScriptBlock $CurrentContext
                        if ($CommandInfo) {
                            $ParameterInfo = Resolve-Parameter $CommandInfo $CurrentContext.Parameter -ParameterInfo
                        } else {
                            $ParameterInfo = Resolve-Parameter $CurrentContext.CommandInfo $CurrentContext.Parameter -ParameterInfo
                        }
                    } else {
                        $ParameterInfo = Resolve-Parameter $CurrentContext.CommandInfo $CurrentContext.Parameter -ParameterInfo
                    }

                    ## Enum
                    if ($ParameterInfo.ParameterType.BaseType -eq [System.Enum]) {
                        $TabExpansionHasOutput = $true
                        Write-Trace "Detected Parameter of type Enum."
                        $PossibleValues = [Enum]::GetNames($ParameterInfo.ParameterType) | Where-Object {$_ -like ($CurrentContext.Argument + "*")} | 
                            New-TabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                    } elseif ($ParameterInfo.ParameterType -eq [System.Boolean]) {
                        ## Treat boolean parameters as enums
                        Write-Trace "Detected Parameter of type Boolean."
                        $PossibleValues = 'true','false' | Where-Object {$_ -like ($CurrentContext.LastWord + "*")} | 
                            New-TabItem -Value {"`$$_"} -Text {$_} -ResultType ParameterValue
                        if ($PossibleValues) {
                            $TabExpansionHasOutput = $true
                        }
                    }

                    ## ValidateSet
                    if (-not $TabExpansionHasOutput) {
                        $ValidateSet = $ParameterInfo.Attributes | Where-Object {$_ -is [System.Management.Automation.ValidateSetAttribute]}
                        if ($ValidateSet) {
                            $TabExpansionHasOutput = $true
                            Write-Trace "Detected Parameter with ValidateSet attribute."
                            $PossibleValues = $ValidateSet | Select-Object -ExpandProperty ValidValues |
                                Where-Object {$_ -like ($CurrentContext.Argument + "*")} | 
                                New-TabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                        }
                    }
                } catch {}
            }

            ## System.Text.Encoding support
            if (-not $TabExpansionHasOutput) {
                if ($ParameterInfo.ParameterType -eq [System.Text.Encoding]) {
                    $TabExpansionHasOutput = $true
                    Write-Trace "Detected Parameter of type System.Text.Encoding."
                    $PossibleValues = "ASCII","BigEndianUnicode","Default","Unicode","UTF32","UTF7","UTF8" |
                        Where-Object {$_ -like ($CurrentContext.Argument + "*")} | 
                        New-TabItem -Value {"[System.Text.Encoding]::$_"} -Text {$_} -ResultType ParameterValue
                }
            }

            ## Ensure that variables get handled
            if ($null -eq $PossibleValues) {$PossibleValues = @()}
            if ($TabExpansionHasOutput -and ($PossibleValues.Count -eq 0) -and ($LastWord -match '^[@\$]')) {
                $TabExpansionHasOutput = $false
            }
        } elseif (($LastWord -match "^-") -and $CurrentContext.isCommandMode) {
            ## Tab complete parameter name

            ## Parameter name registry
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterNameRegistry[$FullCommandName]) {
                Write-Trace "Found entry in ParameterName registry for FullCommandName."

                $ScriptBlock = $TabExpansionParameterNameRegistry[$FullCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext $LastWord | . {process{
                    if ($_ -is [System.String]) {New-TabItem -Value $_ -Text $_ -ResultType ParameterName}
                    else {$_}
                }}
                if ($PossibleValues) {
                    $TabExpansionHasOutput = $true
                }
            }
            if ((-not $TabExpansionHasOutput) -and $TabExpansionParameterNameRegistry[$InternalCommandName]) {
                Write-Trace "Found entry in ParameterName registry for InternalCommandName."

                $ScriptBlock = $TabExpansionParameterNameRegistry[$InternalCommandName]
                $PossibleValues = & $ScriptBlock $CurrentContext $LastWord | . {process{
                    if ($_ -is [System.String]) {New-TabItem -Value $_ -Text $_ -ResultType ParameterName}
                    else {$_}
                }}
                if ($PossibleValues) {
                    $TabExpansionHasOutput = $true
                }
            }

            ## Command info
            if (-not $TabExpansionHasOutput) {
                if ($CurrentContext.CommandInfo) {
                    Write-Trace "Evaluating parameter names based on CommandInfo object."

                    $ParameterName = $LastWord -replace "^-"
                    $PossibleValues = foreach ($Parameter in $CurrentContext.CommandInfo.Parameters.Values) {
                        ##if ($Parameter.Name -like "$ParameterName*" -and $CurrentContext.OtherParameters.Keys -notcontains $Parameter.Name) {
                        if ($Parameter.Name -like "$ParameterName*") {
                            $Value = "-" + $Parameter.Name
                            New-TabItem -Value $Value -Text ("$Value [$($Parameter.ParameterType)]") -ResultType ParameterName
                        }
                    }
                    $TabExpansionHasOutput = $true
                }
            }

            $PossibleValues = foreach ($Value in $PossibleValues) {
                if ($CurrentContext.OtherParameters.Keys -notcontains $Value.CompletionText.Substring(1)) {
                    $Value
                }
            }
        } elseif ($LastToken.Type -eq $_TokenTypes::GroupStart) {
            ## Tab complete method signatures
            $MethodTokens = @([System.Management.Automation.PSParser]::Tokenize($LastWord, [ref]$ParseErrors))
            if ($MethodTokens[-2].Type -eq $_TokenTypes::Member) {
                Write-Trace "Evaluating method signatures."

                $MethodObject = $LastWord.SubString(0, $MethodTokens[-1].Start)
                $PossibleValues = foreach ($Overload in Invoke-Expression "$MethodObject.OverloadDefinitions") {
                    $Parameters = $Overload -replace '^\S+ .+\((.+)?\)','$1'
                    if ($Parameters) {
                        $Parameters = foreach ($Parameter in ($Parameters -split ", ")) {
                            $Type = ($Parameter -split " ")[0] -replace '^System\.'
                            $Name = ($Parameter -split " ")[1]
                            '[{0}] ${1}' -f $Type,$Name
                        }
                        $Parameters = $Parameters -join ", "
                    }
                    $Value = "{0}{1})" -f $LastWord,$Parameters
                    New-TabItem -Value $Value -Text $Value -ResultType Method
                }
                $TabExpansionHasOutput = $true
            }
        } elseif ($CurrentContext.isAssignment -and ($Tokens[0].Type -eq $_TokenTypes::Variable)) {
            if (Test-Path "variable:$($Tokens[0].Content -replace '\$')") {
                $Variable = Get-Variable ($Tokens[0].Content -replace '\$')
                $VariableType = $Variable.Value.GetType()

                ## Strongly typed variables
                if (((Get-Variable ($Tokens[0].Content -replace '\$') -ea SilentlyContinue).Attributes.GetEnumerator() |
                    . {process{$_.GetType().Name}}) -contains "ArgumentTypeConverterAttribute") {
                    if ($VariableType.BaseType -eq [System.Enum]) {
                        ## Tab complete strongly typed enum variables
                        $PossibleValues = [Enum]::GetNames($VariableType) | Where-Object {$_ -like ($CurrentContext.LastWord + "*")} | 
                            New-TabItem -Value {"`"$_`""} -Text {$_} -ResultType ParameterValue
                        if ($PossibleValues) {
                            $TabExpansionHasOutput = $true
                        }
                    }
                } elseif (($VariableType -eq [System.Boolean]) -and ($Tokens[0].Content -like "*Preference")) {
                    ## Tab complete preference variables that are bools
                    $PossibleValues = 'true','false' | Where-Object {$_ -like ($CurrentContext.LastWord + "*")} | 
                        New-TabItem -Value {"`$$_"} -Text {$_} -ResultType ParameterValue
                    if ($PossibleValues) {
                        $TabExpansionHasOutput = $true
                    }
                }
            }
        }

        if ($null -eq $PossibleValues) {$PossibleValues = @()}

        if ($null -eq $PowerTabConfig) {
            ## Something happened to the PowerTabConfig object, recreate it
            CreatePowerTabConfig
        }

        if ($TabExpansionHasOutput) {
            $PossibleValues | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler | . {process{
                if ($_ -is [String]) {
                    if ($QuoteSpaces -and ($_ -match " ") -and ($_ -notmatch "^[`"'].*[`"']`$") -and
                        (($LastToken.Type -eq $_TokenTypes::CommandArgument) -or ($LastWord -eq ""))) {
                        '"' + ($_ -replace '([\$"`])','`$1') + '"'
                    } else {
                        $_
                    }
                } else {
                    if ($QuoteSpaces -and ($_.CompletionText -match " ") -and ($_.CompletionText -notmatch "^[`"'].*[`"']`$") -and
                        (($LastToken.Type -eq $_TokenTypes::CommandArgument) -or ($LastWord -eq ""))) {
                        $_.CompletionText = '"' + ($_.CompletionText -replace '([\$"`])','`$1') + '"'
                    } else {
                        $_
                    }
                }
            }}
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
        ## Send blank to prevent default PowerShell tab expansion
        ""
    } finally {
        ## Remove busy indication on ready or error
        Remove-TabActivityIndicator
    }

    } finally {
        ## Remove busy indication on ready or error
        Remove-TabActivityIndicator

        ## Save PowerTab errors and replace global errors
        $script:PowerTabConfig.Log.Error = $global:Error.Clone()
        $global:Error.Clear()
        $global:Error.AddRange($script:Error)
    }
}

Function New-TabContext {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()
    
    $Properties = @{
            "Command" = ""
            "CommandInfo" = $null
            "Parameter" = ""
            "Argument" = $null
            "ArgumentList" = @()
            "PositionalParameter" = -1
            "PositionalParameters" = @()
            "OtherParameters" = @{}
            "hasCommand" = $false
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

    Write-Trace "Entering core handler."

    $TabExpansionHasOutput = $false

    $OriginalConfirmPreference = $ConfirmPreference
    if ($PowerTabConfig.Core.IgnoreConfirmPreference) {
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
        $Pattern = $Pattern.Split('.')[($LevelCount -1)] + '*'
        . {
            if ('PSBase' -like $Pattern) {$Object + '.PSBase'}
            $Target = Invoke-Expression $Object
            if ($Target -is [System.Management.Automation.ScriptBlock]) {
                $Members = $Target | Get-Member
            } else {
                $Members = Get-Member -InputObject $Target
            }

            if ($PSVersionTable.PSVersion.Major -ge 3) {
                $Members += @(
                    New-Object PSObject -Property @{Name = "ForEach"; MemberType = "Method"}
                    New-Object PSObject -Property @{Name = "Where"; MemberType = "Method"}
                )
            }

            $Members | Where-Object {
                $n = $_.Name
                if (-not $PowerTabConfig.Core.ShowAccessorMethods) {
                    $n -like $Pattern -and $n -notmatch '^[gs]et_'
                } else {
                    $n -like $Pattern
                }
            } | . {process{
                if ($_.MemberType -band $_Method) {
                    ## Return a method...
                    $Value = $Object + '.' + $_.Name + '('
                    New-TabItem -Value $Value -Text $Value -ResultType Method
                } else {
                    ## Return a property...
                    $Value = $Object + '.' + $_.Name
                    New-TabItem -Value $Value -Text $Value -ResultType Property
                }
            }}
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
        if ($Name.IndexOfAny($_varsRequiringQuotes) -ge 0) {
            "{$Name}"
        } else {
            $Name
        }
    }

    ## Main tabcompletion , check line for patterns, select completion method and invoke handler

    ## Evaluate last block
    switch -regex ($LastBlock)  {
        ## Handle multilevel property and method expansion on simple () Blocks
        '(^| )\((.+)\)\.(.*)' {
            Write-Trace "Core Handler: Evaluating nested statements."

            &{ trap {continue}
                Resolve-Member -Object "($($Matches[2]))" -Pattern $Matches[3] |
                    Invoke-TabItemSelector $LastBlock -SelectionHandler $SelectionHandler | . {process{
                        $TabExpansionHasOutput = $true
                        if ($_.IndexOf(' ') -ge 0 ) {
                            ([Regex]::Split($_,' '))[-1].Trim()
                        } else {
                            $_
                        }
                    }}
            }
            if ($TabExpansionHasOutput) {
                ## Tab expansion handled, don't do anything more
                return
            }
        }
    }

    ## Evaluate last word
    [Object[]]$PossibleValues = @()
    $PossibleValues = switch -regex ($LastWord)  {
        ## Handle inline type search, e.g. new-object .identityreference<tab> or .identityre<tab> (oisin) 
        '^(\[*?)\.(\w+)$' {
            Write-Trace "Core Handler: Evaluating inline type search."

            $TypeName = $Matches[2]
            Get-TabExpansion "*.${TypeName}*" Types |
                New-TabItem -Value {if ($Matches[1] -eq '[') {"[$($_.Name)]"} else {$_.Name}} -Text {$_.Name} -ResultType Type
            $SelectorLastWord = $LastWord.Replace('[', '')
            break
        }

        ## Members of scriptblock
        '(.*\})\.([^\.]*)$' {
            Write-Trace "Core Handler: Evaluating members of a scriptblock."

            $ScriptBlock = $Matches[1]
            $Member = $Matches[2]
            {} | Get-Member | Where-Object {
                $n = $_.Name
                if (-not $PowerTabConfig.Core.ShowAccessorMethods) {
                    $n -like "$Member*" -and $n -notmatch '^[gs]et_'
                } else {
                    $n -like "$Member*"
                }
            } | . {process{
                if ($_.MemberType -band $_Method) {
                    ## Return a method...
                    $Value = $ScriptBlock + '.' + $_.Name + '('
                    New-TabItem -Value $Value -Text $Value -ResultType Method
                } else {
                    ## Return a property...
                    $Value = $ScriptBlock + '.' + $_.Name
                    New-TabItem -Value $Value -Text $Value -ResultType Property
                }
            }}
            $SelectorLastWord = "$ScriptBlock.$Member"
            break
        }

        ## Completion on Shares (commented lines without DLL but need admin rights )
        '^(\\\\|//)(?<Computer>[^\\/]+)[\\/](?<Share>[^\\/]*)$' {
            Write-Trace "Core Handler: Evaluating file shares."

            $ComputerName = $Matches.Computer
            $ShareName = $Matches.Share
            if (isWindows) {
                Get-CimInstance -Class Win32_Share -ComputerName $ComputerName -Filter "name like '$($ShareName)%'" |
                    Sort-Object Name | New-TabItem -Value {"\\$ComputerName\" + $_.Name} -Text {"\\$ComputerName\" + $_.Name + " - " + $_.Description} -ResultType ProviderContainer
            }
            $SelectorLastWord = $LastWord
            break
        }

        ## Completion on computers in database            
        '^(\\\\|//)(?<Computer>[^\\/]*)$' {
            Write-Trace "Core Handler: Evaluating computer names from database."

            foreach ($Computer in Get-TabExpansion "$($Matches.Computer)*" Computer) {
                $Value = "\\" + $Computer.Text
                New-TabItem -Value $Value -Text $Value -ResultType ProviderContainer
            }
            $SelectorLastWord = $LastWord
            break
        }

        ## Variable "In-Place" expansion on \[tab]
        '.*(\$[^\\]+)\\$' {
            Write-Trace "Core Handler: Evaluating variable for inplace expansion."

            $val = $ExecutionContext.InvokeCommand.ExpandString($Matches[1])
            ($Matches[0] -replace ([Regex]::Escape($Matches[1])), $val).TrimEnd('\')
            break
        }

        ## Replace <command>-? with call to Get-Help
        '.*\-\?' {
            Write-Trace "Core Handler: Evaluating use of -? short hand."

            "Get-Help " + $LastWord.Replace('-?', ' -')
        }

        ## PSDrive expansion on :[tab]
        '^:$' {
            Write-Trace "Core Handler: Evaluating PSDrive names."

            Get-PSDrive | New-TabItem -Value {$_.Name + ':'} -Text {$_.Name + ':'} -ResultType ProviderContainer
            $SelectorLastWord = ''
        }

        ## History completion against either #<pattern> or #<id>
        '^#(.*)' {
            Write-Trace "Core Handler: Evaluating command history."

            ## Only do history if there is not a command in the current context
            if (-not $Context.isCommandMode) {
                $Pattern = $Matches[1]
                if ($Pattern -match '^[0-9]+$') {
                    @(Get-History -Id $Pattern -ErrorAction SilentlyContinue)[0].CommandLine
                } else {
                    if ((Get-Module PSReadline) -and (Test-Path (Get-PSReadlineOption).HistorySavePath)) {
                        ## TODO: Find a way to support multi-line commands
                        $history = Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object {$_ -like "*$Pattern*"} |
                            Where-Object {$_ -notmatch '`' <# exclude multi-line #>}
                        [Array]::Reverse($history)
                        $history | Select-Object -Unique | New-TabItem -Value {$_} -Text {$_} -ResultType History
                    } else {
                        Get-History -Count 32767 | Where-Object {$_.CommandLine -like "*$Pattern*"} | Sort-Object Id -Descending |
                            Select-Object -ExpandProperty CommandLine -Unique | New-TabItem -Value {$_} -Text {$_} -ResultType History
                    }
                    $SelectorLastWord = $Pattern
                }
                break
            }
        }

        ## DataGrid GUI Shortcuts
        '^a_(.*)' {Get-Help "about_$($Matches[1])*" | Select-Object Name,Synopsis,Length | Out-DataGridView Name |
            . {process{Get-Help $_}}}
        ## TODO: Add description?
        '^w_(.*)' {Get-TabExpansion "win32_$($Matches[1])*" WMI | Select-Object Name | Out-DataGridView Name}
        '^t_(.*)' {Get-TabExpansion "*$($Matches[1])*" Types | Where-Object {$_.Name -ne "Dummy"} |
            Select-Object Name | Out-DataGridView Name}
        '^c_(.*)' {Get-TabExpansion "$($Matches[1])*" | Select-Object Text | Out-DataGridView Text}
        ## TODO: Add synopsis?
        '^f_' {Get-ChildItem function: | Select-Object Name | Out-DataGridView Name}
        ## TODO: I think this needs some work
        '^d_' {Get-ChildItem | Select-Object Mode,LastWriteTime,Length,Name,FullName | Out-DataGridView FullName}
        '^h_' {Get-History -Count 100 | Out-DataGridView Commandline}

        ## WMI completion
        '(win32_.*|cim_.*|MSFT_.*)' {
            ## TODO:  Should this be removed from the core handler?
            Write-Trace "Core Handler: Evaluating WMI class names."

            Get-TabExpansion "$($Matches[1])*" WMI | New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType Type
            $SelectorLastWord = $LastWord
            break
        }

        ## Handle property and method expansion on variables
        '\$(.+)\.(.*)' {
            Write-Trace "Core Handler: Evaluating members of a variable."

            Resolve-Member -Object ('$' + $Matches[1]) -Pattern $Matches[2]
            $SelectorLastWord = $LastWord
            break
        }

        ## Translate typename to New-Object statement (ex: [String]=<TAB>)
        '^(\[.*\])=(\w*)$' {
            Write-Trace "Core Handler: Evaluating short hand for new object creation."

            "New-Object $($Matches[1].Replace('[','').Replace(']',''))"
            break
        }

        ## Handle Static methods of Types
        '(\[.*\])::(.*)$' {
            Write-Trace "Core Handler: Evaluating static members of a type."

            $LastType = $Matches[1]
            $Level = $Matches[2].Split('.').Count

            if ($Level -gt 1) {
                $LastType += '::' + $Matches[2].SubString(0, $Matches[2].LastIndexOf('.'))
                $Pattern = $Matches[2].Split('.')[-1]
                Resolve-Member -Object $LastType -Pattern $Pattern
            } else {
                $Pattern = $Matches[2].Split('.')[($Level -1)] + '*'
                Invoke-Expression "$($Matches[1]) | Get-Member -Static" |
                    Where-Object {$_.Name -like $Pattern -and $_.Name -notmatch '^[ge]et_'} |
                    . {process{
                        if ($_.MemberType -band $_Method) {
                            $Value = "${LastType}::$($_.Name)" + '('
                            New-TabItem -Value $Value -Text $Value -ResultType Method
                        } else {
                            $Value = "${LastType}::$($_.Name)"
                            New-TabItem -Value $Value -Text $Value -ResultType Property
                        }
                    }}
            }
            $SelectorLastWord = $LastWord
            break
        }

        ## Handle Static methods of types in Variables
        '(\$.*)::(.*)$' {
            Write-Trace "Core Handler: Evaluating static members of a variable."

            $LastType = $Matches[1]
            $Level = $Matches[2].Split('.').Count
            $gt = ''

            if ((Invoke-Expression "$LastType.GetType().Name") -ne 'RuntimeType') {$gt = '.GetType'}
            if ($Level -gt 1) {
                $LastType += '::' + $Matches[2].SubString(0, $Matches[2].LastIndexOf('.'))
                $Pattern = $Matches[2].Split('.')[-1]
                Resolve-Member -Object $LastType -Pattern $Pattern
                $SelectorLastWord = $LastWord
            } else {
                $Pattern = $Matches[2].Split('.')[($Level -1)] + '*'
                Invoke-Expression "$($Matches[1]) | Get-Member -Static" |
                    Where-Object {$_.Name -like $Pattern -and $_.Name -notmatch '^[ge]et_'} |
                    . {process{
                        if ($_.MemberType -band $_Method) {
                            $Value = "${LastType}${gt}::$($_.Name)" + '('
                            New-TabItem -Value $Value -Text $Value -ResultType Method
                        } else {
                            $Value = "${LastType}${gt}::$($_.Name)"
                            New-TabItem -Value $Value -Text $Value -ResultType Property
                        }
                    }}
                $SelectorLastWord = $LastWord.Replace('::',"${gt}::")
            }
            break
        }

        ## Handle enums and Constructors of Types
        '(\[.*\]):*$' {
            Write-Trace "Core Handler: Evaluating enum values and constructors for types."

            $LastType = $Matches[1].Split(',')[-1]
            $BaseType = (Invoke-Expression "$LastType.BaseType.FullName")
            if ($BaseType -eq 'System.Enum') {
                Invoke-Expression "[Enum]::GetNames($LastType)" |
                    New-TabItem -Value {"${LastType}::$_"} -Text {"${LastType}::$_"} -ResultType ParameterValue
                $SelectorLastWord = ($LastType + '::')
            } else {
                $Constructors = Invoke-Expression "$LastType.GetConstructors()" | . {process{
                    $Parameters = foreach ($Parameter in $_.GetParameters()) {
                        '[{0}] ${1}' -f ($Parameter.ParameterType -replace '^System\.'), $Parameter.Name
                    }
                    if ($Parameters) {
                        $Param = [String]::Join(', ',$Parameters)
                        "New-Object $($LastType.Trim('[]')) ($Param)".Replace('([])','()')
                    } else {
                        "New-Object $($LastType.Trim('[]'))".Replace('([])','()')
                    }
                }}
                if ($Constructors) {
                    $Constructors | New-TabItem -Value {$_} -Text {$_} -ResultType Method
                    $SelectorLastWord = $LastType
                } else {
                    $LastWord
                }
            }
            break
        }

        ## Handle members of Types (runtype)
        '^(\[.*\]).(\w*)$' {
            Write-Trace "Core Handler: Evaluating non-static members of a type."

            $LastType = $Matches[1].Split(',')[-1]
            Invoke-Expression "$LastType | Get-Member" | Where-Object {$_.Name -like "$($Matches[2])*"} | . {process{
                if ($_.MemberType -band $_Method) {
                    $Value = "$LastType.$($_.Name)" + '('
                    New-TabItem -Value $Value -Text $Value -ResultType Method
                } else {
                    $Value = "$LastType.$($_.Name)"
                    New-TabItem -Value $Value -Text $Value -ResultType Property
                }
            }}
            $SelectorLastWord = $LastWord
            break
        } 

        ## Handle namespace and type names 
        '^\[(.*)$' {
            Write-Trace "Core Handler: Evaluating namespaces or type names."

            $Matched = $Matches[1]
            $Dots = $Matches[1].Split(".").Count - 1
            $res = @()
            $res += foreach ($Namespace in $dsTabExpansionDatabase.Tables['Types'].Select("NS like '$($Matched)%' and DC = $($Dots + 1)") |
                    Select-Object -Unique NS) {
                $Value = "[$($Namespace.NS)"
                New-TabItem -Value $Value -Text $Value -ResultType Namespace
            }
            $res += foreach ($Namespace in $dsTabExpansionDatabase.Tables['Types'].Select("NS like 'System.$($Matched)%' and DC = $($Dots + 2)") |
                    Select-Object -Unique NS) {
                $Value = "[$($Namespace.NS)"
                New-TabItem -Value $Value -Text $Value -ResultType Namespace
            }
            if ($Dots -gt 0) {
                $res += foreach ($Type in $dsTabExpansionDatabase.Tables['Types'].Select("Name like '$($Matched)%' and DC = $Dots")) {
                    $Value = "[$($Type.Name)]"
                    New-TabItem -Value $Value -Text $Value -ResultType Type
                }
                $res += foreach ($Type in $dsTabExpansionDatabase.Tables['Types'].Select("Name like 'System.$($Matched)%' and DC = $($Dots + 1)")) {
                    $Value = "[$($Type.Name)]"
                    New-TabItem -Value $Value -Text $Value -ResultType Type
                }
            }
            $res | Where-Object {$_} | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler -ForceList:$ForceList
            break
        }

        ## Handle expansions for both "Scope Variable Name" and "Type Variable Names"
        '^\$(\w+):(\w*)$' {
            Write-Trace "Core Handler: Evaluating variable scope or type."

            $Type = $Matches[1]     # function, variable, global, etc.
            $TypeName = $Matches[2] # e.g. in '$function:C', value will be 'C'

            if ($_ScopeNames -contains $Type) {
                # Scope variable name expansion ($global:, $script:, etc.)
                $Variables = foreach ($ScopeVariable in (Get-Variable "$TypeName*" -Scope $Type)) {
                    '$' + (QuoteVariable ($Type + ":" + $ScopeVariable.Name))
                }
            } else {
                # Type variable name expansion ($function:, $variable:, $env:, etc.)
                $Variables = foreach ($t in (Get-ChildItem ($Type + ":" + $TypeName + '*') | Sort-Object Name)) {
                    '$' + (QuoteVariable ($Type + ":" + $t.Name))
                }
            }
            $Variables | New-TabItem -Value {$_} -Text {$_} -ResultType Variable
            $SelectorLastWord = $LastWord
            break
        }

        ## Handle variable name expansion
        '^([\$@])(\w*)$' {
            Write-Trace "Core Handler: Evaluating variable name."

            $VarName = $Matches[2]
            $Variables = foreach ($Variable in Get-Variable "$VarName*" -Scope Global) {
                $Matches[1] + (QuoteVariable $Variable.Name)
            }
            $Variables | New-TabItem -Value {$_} -Text {$_} -ResultType Variable
            $SelectorLastWord = $LastWord
            break
        }

        ## Completion on cmdlets, function, aliases and native commands with defined shortcuts and custom additions from database

        ## Native commands / scripts in path
        "(.*)$([Regex]::Escape($PowerTabConfig.Core.ShortcutChars.Native))`$" { 
            Write-Trace "Core Handler: Evaluating native commands and scripts only (special character)."

            Get-Command -CommandType ExternalScript -Name "$($Matches[1])*" |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
            Get-Command -CommandType Application -Name "$($Matches[1])*" |
                Where-Object {($env:PATHEXT).Split(";") -contains $_.Extension} |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command
            $SelectorLastWord = $Matches[1]
            break
        }

        ## Aliases
        "(.+)$([Regex]::Escape($PowerTabConfig.Core.ShortcutChars.Alias))`$" {
            Write-Trace "Core Handler: Evaluating aliases only (special character)."

            if ($DoubleTab -or $PowerTabConfig.ConsoleList.AliasQuickExpand) {
                GetCommand -CommandType Alias -Name $Matches[1] | New-TabItem -Value {$_.Definition} -Text {$_.Definition} -ResultType Command
                $SelectorLastWord = $Matches[1]
            } else {
                $SelectorLastWord = $null
            }
            Get-TabExpansion $Matches[1] Alias | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType Command
            break
        }

        ## Custom
        "(.*)$([Regex]::Escape($PowerTabConfig.Core.ShortcutChars.Custom))`$" {
            Write-Trace "Core Handler: Evaluating custon results from database only (special character)."

            Get-TabExpansion "$($Matches[1])*" Custom | New-TabItem -Value {$_.Text} -Text {$_.Text}
            $SelectorLastWord = $Matches[1]
            break
        }

        ## Invoke
        "(.+)$([Regex]::Escape($PowerTabConfig.Core.ShortcutChars.Invoke))`$" {
            Write-Trace "Core Handler: Evaluating invoke results from database only (special character)."

            Get-TabExpansion "$($Matches[1])*" Invoke | . {process{
                $ExecutionContext.InvokeCommand.InvokeScript($_.Text) | New-TabItem -Value {$_} -Text {$_}
            }}
            $SelectorLastWord = $Matches[1]
            break
        }

        ## Call function
        "(.*)$([Regex]::Escape($PowerTabConfig.Core.ShortcutChars.CustomFunction))`$" {
            Write-Trace "Core Handler: Calling custom user function."

            if ($PowerTabConfig.Core.CustomFunctionEnabled) {
                & $PowerTabConfig.Core.CustomUserFunction $Context | 
                    New-TabItem -Value {$_} -Text {$_}
                $SelectorLastWord = $Matches[1]
            }
            break
        }
    } ## End of switch -regex $LastWord

    if ($null -eq $PossibleValues) {$PossibleValues = @()}

    if ((-not $PossibleValues) -and 
            (($Context.LastToken -eq [System.Management.Automation.PSTokenType]::Command -and $LastWord) -or
            (-not $Context.hasCommand))) {
        ## Try completing on commands and aliases
        Write-Trace "Core Handler: Evaluating cmdlet and function names."

        $CommandTypes = "Function","ExternalScript","Filter","Cmdlet","Alias"
        if ($PSVersionTable.PSVersion -ge "3.0") {
            $CommandTypes += "Workflow"
        }

        if ($LastWord -match "\\") {
            ## Full name usage
            $Module = $LastWord.Substring(0, $LastWord.Indexof("\"))
            $CommandName = $LastWord.Substring($LastWord.Indexof("\") + 1, $LastWord.length - ($LastWord.Indexof("\") + 1))
            if (Get-Module $Module) {
                $PossibleValues = @(GetCommand -CommandType $CommandTypes -Name "$CommandName*" -Module $Module |
                    New-TabItem -Value {"${Module}\" + $_.Name} -Text {$_.Name} -ResultType Command)
            }
        } else {
            $PossibleValues = @(GetCommand -CommandType $CommandTypes -Name "$LastWord*" |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -ResultType Command)
        }

        $SelectorLastWord = $LastWord
    }

    if ($PossibleValues) {$TabExpansionHasOutput = $true}

    if ($TabExpansionHasOutput) {
        $PossibleValues | Invoke-TabItemSelector $LastWord -SelectionHandler $SelectionHandler
    } elseif ((-not $TabExpansionHasOutput) -and $PowerTabConfig.Core.FileSystemExpand) {
        ## Filesystem Completion
        Invoke-ProviderPathHandler $LastWord
    }

    ## Reset confirm preference even if we did not change it
    $ConfirmPreference = $OriginalConfirmPreference

}  # end-function
