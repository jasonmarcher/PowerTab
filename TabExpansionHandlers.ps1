
<########################
## Notes

- The closures in this file make the code run outside the PowerTab module's context.  This avoids
some problems like Get-Module only seeing the modules loaded within PowerTab, or private functions
showing up from Get-Command.
########################>


#########################
## Command handlers
#########################

## Alias
& {
    $AliasHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-Alias -Name "$Argument*" | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Export-Alias" $AliasHandler -Type "Command"
    Register-TabExpansion "Get-Alias" $AliasHandler -Type "Command"
}

## Get-Command
Register-TabExpansion "Get-Command" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    if (($Context.Parameter -eq "ArgumentList") -and ($Context.PositionalParameter -eq 0)) {
        $Context.Parameter = "Name"  ## Fix for odd default parameter set on Get-Command
    }
    switch -exact ($Context.Parameter) {
        'Module' {
            $TabExpansionHasOutput.Value = $true
            Get-Module "$Argument*" | Select-Object -ExpandProperty Name | Sort-Object
        }
        'Name' {
            $TabExpansionHasOutput.Value = $true
            $Parameters = @{}
            if ($Context.OtherParameters["Module"]) {
                $Parameters["Module"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["Module"]
            }
            if ($Context.OtherParameters["CommandType"]) {
                $Parameters["CommandType"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["CommandType"]
            } else {
                $Parameters["CommandType"] = "Alias","Function","Filter","Cmdlet"
                if ($PSVersionTable.PSVersion -ge "3.0") {
                    $Parameters["CommandType"] += "Workflow"
                }
            }
            Get-Command "$Argument*" @Parameters | Select-Object -ExpandProperty Name
        }
        'Noun' {
            $TabExpansionHasOutput.Value = $true
            Get-Command -CommandType Cmdlet,Filter,Function | Where-Object {$_.Name -match "^[^-]+-(?<Noun>$Argument.*)"} |
                ForEach-Object {$Matches.Noun} | Sort-Object -Unique
        }
        'Verb' {
            $TabExpansionHasOutput.Value = $true
            Get-Verb "$Argument*" | Select-Object -ExpandProperty Verb | Sort-Object
        }
    }
}.GetNewClosure()

## Reset-ComputerMachinePassword
Register-TabExpansion "Reset-ComputerMachinePassword" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Server' {
            if ($Argument -notmatch '^\$') {
                $TabExpansionHasOutput.Value = $true
                Get-TabExpansion "$Argument*" Computer | Select-Object -ExpandProperty "Text"
            }
        }
    }
}.GetNewClosure()

## ComputerRestore
& {
    $ComputerRestoreHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Drive' {
                $TabExpansionHasOutput.Value = $true
                Get-PSDrive -PSProvider FileSystem "$Argument*" | New-TabItem -Value {$_.Root} -Text {$_.Root} -Type Drive
            }
        }
    }.GetNewClosure()
    
    $ComputerRestorePointHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'RestorePoint' {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                foreach ($Point in Get-ComputerRestorePoint -ErrorAction Stop) {
                    if ($Point.Description.Length -gt 50) {
                        $Description = $Point.Description.SubString(0, 50)
                    } else {
                        $Description = $Point.Description
                    }
                    $Text = "{0}: {1} ({2})" -f $Point.SequenceNumber,[DateTime]::ParseExact($Point.CreationTime, "yyyyMMddHHmmss.ffffff-000", $null),$Description
                    New-TabItem -Value $Point.SequenceNumber -Text $Text -Type ComputerRestorePoint
                }
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Disable-ComputerRestore" $ComputerRestoreHandler -Type Command
    Register-TabExpansion "Enable-ComputerRestore" $ComputerRestoreHandler -Type Command
    Register-TabExpansion "Get-ComputerRestorePoint" $ComputerRestorePointHandler -Type Command
    Register-TabExpansion "Restore-Computer" $ComputerRestorePointHandler -Type Command
}

## Counter
& {
    $CounterHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Counter' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Counter -ListSet * @Parameters | Select-Object -ExpandProperty PathsWithInstances | 
                    Where-Object {$_ -like "*$Argument*"} | Sort-Object
            }
            'ListSet' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Counter -ListSet "$Argument*" @Parameters | Select-Object -ExpandProperty CounterSetName
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Get-Counter" $CounterHandler -Type "Command"
    Register-TabExpansion "Import-Counter" $CounterHandler -Type "Command"
}

## Event
& {
    $GetEventHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'SourceIdentifier' {
                $TabExpansionHasOutput.Value = $true
                Get-Event "$Argument*" | Select-Object -ExpandProperty SourceIdentifier | Sort-Object
            }
            'EventIdentifier' {
                $TabExpansionHasOutput.Value = $true
                Get-Event | Select-Object -ExpandProperty EventIdentifier
            }
        }
    }.GetNewClosure()
    $EventHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Class' {
                $TabExpansionHasOutput.Value = $true
                ## TODO: escape special characters?
                Get-TabExpansion "$Argument*" WMI | Select-Object -ExpandProperty Name
            }
            'EventName' {
                if ($Context.OtherParameters["InputObject"]) {
                    $TabExpansionHasOutput.Value = $true
                    Invoke-Expression $Context.OtherParameters["InputObject"] | Get-Member | 
                        Where-Object {$_.MemberType -eq "Event" -and $_.Name -like "$Argument*"} | Select-Object -ExpandProperty Name
                }
            }
            'Namespace' {
                $TabExpansionHasOutput.Value = $true
                if ($Argument -notlike "ROOT\*") {
                    $Argument = "ROOT\$Argument"
                }
                if ($Context.OtherParameters["ComputerName"]) {
                    $ComputerName = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                } else {
                    $ComputerName = "."
                }
                
                $ParentNamespace = $Argument -replace '\\[^\\]*$'
                $Namespaces = New-Object System.Management.ManagementClass "\\$ComputerName\${ParentNamespace}:__NAMESPACE"
                $Namespaces = foreach ($Namespace in $Namespaces.PSBase.GetInstances()) {"{0}\{1}" -f $Namespace.__NameSpace,$Namespace.Name}
                $Namespaces | Where-Object {$_ -like "$Argument*"} | Sort-Object
            }
            'SourceIdentifier' {
                $TabExpansionHasOutput.Value = $true
                Get-Event "$Argument*" | Select-Object -ExpandProperty SourceIdentifier | Sort-Object
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Get-Event" $GetEventHandler -Type "Command"
    Register-TabExpansion "Get-EventSubscriber" $EventHandler -Type "Command"
    Register-TabExpansion "New-Event" $EventHandler -Type "Command"
    Register-TabExpansion "Register-ObjectEvent" $EventHandler -Type "Command"
    Register-TabExpansion "Register-EngineEvent" $EventHandler -Type "Command"
    Register-TabExpansion "Register-WmiEvent" $EventHandler -Type "Command"
    Register-TabExpansion "Remove-Event" $EventHandler -Type "Command"
    Register-TabExpansion "Unregister-Event" $EventHandler -Type "Command"
    Register-TabExpansion "Wait-Event" $EventHandler -Type "Command"
}

## EventLog
& {
    $EventLogHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Category' {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                $Categories = (
                    @{'Id'='0';'Name'='None'},
                    @{'Id'='1';'Name'='Devices'},
                    @{'Id'='2';'Name'='Disk'},
                    @{'Id'='3';'Name'='Printers'},
                    @{'Id'='4';'Name'='Services'},
                    @{'Id'='5';'Name'='Shell'},
                    @{'Id'='6';'Name'='System Event'},
                    @{'Id'='7';'Name'='Network'}
                )
                $Categories | Where-Object {$_.Name -like "$Argument*"} |
                    New-TabItem -Value {$_.Id} -Text {$_.Name} -Type EventLogCategory
            }
            'LogName' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-EventLog -List -AsString @Parameters | Where-Object {$_ -like "$Argument*"} |
                    New-TabItem -Value {$_} -Text {$_} -Type EventLog
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Clear-EventLog" $EventLogHandler -Type "Command"
    Register-TabExpansion "Get-EventLog" $EventLogHandler -Type "Command"
    Register-TabExpansion "Limit-EventLog" $EventLogHandler -Type "Command"
    Register-TabExpansion "Remove-EventLog" $EventLogHandler -Type "Command"
    Register-TabExpansion "Write-EventLog" $EventLogHandler -Type "Command"
}

## Get-FormatData
Register-TabExpansion "Get-FormatData" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'TypeName' {
            if ($Argument -notmatch '^\.') {
                ## TODO: Find way to differentiate namespaces from types
                $TabExpansionHasOutput.Value = $true
                $Dots = $Argument.Split(".").Count - 1
                $res = @()
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like '$Argument*' and DC = $($Dots + 1)") |
                    Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -Type Namespace
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like 'System.$Argument*' and DC = $($Dots + 2)") |
                    Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -Type Namespace
                if ($Dots -gt 0) {
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like '$Argument*' and DC = $Dots") |
                        Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -Type Type
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like 'System.$Argument*' and DC = $($Dots + 1)") |
                        Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -Type Type
                }
                $res | Where-Object {$_}
            }
        }
    }
}

## Get-Help
& {
    $HelpHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                if ($Argument -like "about_*") {
                    $Commands = Get-Help "$Argument*" | Select-Object -ExpandProperty Name
                    if ($Commands) {
                        $TabExpansionHasOutput.Value = $true
                        $Commands
                    }
                } else {
                    $CommandTypes = "Function","ExternalScript","Filter","Cmdlet","Alias"
                    if ($PSVersionTable.PSVersion -ge "3.0") {
                        $CommandTypes += "Workflow"
                    }
                    $Commands = Get-Command "$Argument*" -CommandType $CommandTypes | Select-Object -ExpandProperty Name
                    if ($Commands) {
                        $TabExpansionHasOutput.Value = $true
                        $Commands
                    }
                }
            }
            'Parameter' {
                $TabExpansionHasOutput.Value = $true
                if ($Context.OtherParameters["Name"]) {
                    $Command = Resolve-TabExpansionParameterValue $Context.OtherParameters["Name"]
                } else {
                    $Command = Resolve-TabExpansionParameterValue $Context.PositionalParameters[0]
                }
                $CommandInfo = try {& (Get-Module PowerTab) Resolve-Command $Command -CommandInfo -ErrorAction "Stop"} catch {}
                if ($CommandInfo) {
                    foreach ($Parameter in $CommandInfo.Parameters.Values) {
                        if ($Parameter.Name -like "$Argument*") {
                            New-TabItem -Value $Parameter.Name -Text $Parameter.Name -Type Parameter
                        }
                    }
                }
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Get-Help" $HelpHandler -Type "Command"
    Register-TabExpansion "help" $HelpHandler -Type "Command"
}

## Get-HotFix
Register-TabExpansion "Get-HotFix" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Id' {
            $TabExpansionHasOutput.Value = $true
            $Parameters = @{}
            if ($Context.OtherParameters["ComputerName"]) {
                $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
            }
            Get-HotFix @Parameters | Where-Object {$_.HotFixID -like "$Argument*"} | Select-Object -ExpandProperty HotFixID
        }
    }
}.GetNewClosure()

## ConvertTo-HTML
Register-TabExpansion "ConvertTo-HTML" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Label=""; Expression={$_.}}'
            }
        }
    }
}

## ItemProperty
& {
    $ItemPropertyHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                $Path = "."
                if ($Context.OtherParameters["Path"]) {
                    $Path = Resolve-TabExpansionParameterValue $Context.OtherParameters["Path"]
                }
                Get-ItemProperty -Path $Path -Name "$Argument*" | Get-Member | Where-Object {
                    (("Property","NoteProperty") -contains $_.MemberType) -and
                    (("PSChildName","PSDrive","PSParentPath","PSPath","PSProvider") -notcontains $_.Name)
                } | Select-Object -ExpandProperty Name -Unique
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Clear-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Copy-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Get-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Move-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Remove-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Rename-ItemProperty" $ItemPropertyHandler -Type "Command"
    Register-TabExpansion "Set-ItemProperty" $ItemPropertyHandler -Type "Command"
}

## Job
& {
    $JobHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Id' {
                $TabExpansionHasOutput.Value = $true
                Get-Job | Select-Object -ExpandProperty Id
            }
            'InstanceId' {
                $TabExpansionHasOutput.Value = $true
                Get-Job | Select-Object -ExpandProperty InstanceId
            }
            'Location' {
                $TabExpansionHasOutput.Value = $true
                Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -Type Computer
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-Job -Name "$Argument*" | Select-Object -ExpandProperty Name
            }
            'Job' {
                if ($Argument -notlike '$*') {
                    $TabExpansionHasOutput.Value = $true
                    $QuoteSpaces.Value = $false
                    foreach ($Job in Get-Job -Name "$Argument*") {'(Get-Job "{0}")' -f $Job.Name}
                }
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Get-Job" $JobHandler -Type "Command"
    Register-TabExpansion "Receive-Job" $JobHandler -Type "Command"
    Register-TabExpansion "Remove-Job" $JobHandler -Type "Command"
    Register-TabExpansion "Stop-Job" $JobHandler -Type "Command"
    Register-TabExpansion "Wait-Job" $JobHandler -Type "Command"
}

## Get-Module
Register-TabExpansion "Get-Module" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $Parameters = @{}
            if ($Context.OtherParameters["All"]) {
                $Parameters["All"] = $true
            }
            if ($Context.OtherParameters["ListAvailable"]) {
                $Parameters["ListAvailable"] = $true
            }
            $Modules = @(Get-Module "$Argument*" @Parameters | Sort-Object Name)
            if ($Modules.Count -gt 0) {
                $TabExpansionHasOutput.Value = $true
                $Modules | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Module
            }
        }
    }
}.GetNewClosure()

## Import-Module
Register-TabExpansion "Import-Module" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            if ($Argument -notmatch '^\.') {
                $Modules = @(Find-Module "$Argument*" | Sort-Object BaseName)
                if ($Modules.Count -gt 0) {
                    $TabExpansionHasOutput.Value = $true
                    $Modules | New-TabItem -Value {$_.BaseName} -Text {$_.BaseName} -Type Module
                }
            }
        }
    }
}

## Remove-Module
Register-TabExpansion "Remove-Module" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-Module "$Argument*" | Sort-Object Name |
                New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Module
        }
    }
}.GetNewClosure()

## Group-Object
Register-TabExpansion "Group-Object" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Expression={$_.}}'
            }
        }
    }
}

## New-Object
Register-TabExpansion "New-Object" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'ArgumentList' {
            $TabExpansionHasOutput.Value = $true
            $QuoteSpaces.Value = $false

            if ($Context.OtherParameters["TypeName"]) {
                $TypeName = Resolve-TabExpansionParameterValue $Context.OtherParameters["TypeName"]
            } elseif ($Context.PositionalParameter -ge 0) {
                $TypeName = Resolve-TabExpansionParameterValue $Context.PositionalParameters[0]
            } else {
                ## TODO: Localize
                throw "No TypeName specified."
            }

            Invoke-Expression "[$TypeName].GetConstructors()" | ForEach-Object {
                $Parameters = foreach ($Parameter in $_.GetParameters()) {
                    '[{0}] ${1}' -f ($Parameter.ParameterType -replace '^System\.'), $Parameter.Name
                }
                if ($Parameters) {
                    $Param = "({0})" -f [String]::Join(', ',$Parameters)
                    New-TabItem -Value $Param -Text $Param -Type Constructor
                } else {
                    New-TabItem -Value "()" -Text "() <Empty Constructor>" -Type Constructor
                }
            }
        }
        'ComObject' {
            ## TODO: Maybe cache these like we do with .NET types and WMI object names?
            ## TODO: [workitem:13]
            $TabExpansionHasOutput.Value = $true
            Get-TabExpansion "$Argument*" COM | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type COMObject
        }
        'TypeName' {
            if ($Argument -notmatch '^\.') {
                ## TODO: Find way to differentiate namespaces from types
                $TabExpansionHasOutput.Value = $true
                $Dots = $Argument.Split(".").Count - 1
                $res = @()
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like '$Argument*' and DC = $($Dots + 1)") |
                    Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -Type Namespace
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("NS like 'System.$Argument*' and DC = $($Dots + 2)") |
                    Select-Object -Unique -ExpandProperty NS | New-TabItem -Value {$_} -Text {"$_."} -Type Namespace
                if ($Dots -gt 0) {
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like '$Argument*' and DC = $Dots") |
                        Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -Type Type
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("Name like 'System.$Argument*' and DC = $($Dots + 1)") |
                        Select-Object -ExpandProperty Name | New-TabItem -Value {$_} -Text {$_} -Type Type
                }
                $res | Where-Object {$_}
            }
        }
    }
}

## Select-Object
Register-TabExpansion "Select-Object" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
            }
        }
    }
}

## Sort-Object
Register-TabExpansion "Sort-Object" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Expression={$_.}}'
                '@{Expression={$_.}; Ascending=$true}'
                '@{Expression={$_.}; Descending=$true}'
            }
        }
    }
}

## Out-Printer
Register-TabExpansion "Out-Printer" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-WMIObject Win32_Printer -Filter "Name LIKE '$Argument%'" | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Printer
        }
    }
}.GetNewClosure()

## Process
& {
    $ProcessHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Id' {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                if ($Argument -match '^[0-9]+$') {
                    Get-Process | Where-Object {$_.Id.ToString() -like "$Argument*"} |
                        New-TabItem -Value {$_.Id} -Text {"{0,-4} {1}" -f ([String]$_.Id),$_.Name} -Type Process
                } else {
                    Get-Process | Where-Object {$_.Name -like "$Argument*"} |
                        New-TabItem -Value {$_.Id} -Text {"{0,-4} {1}" -f ([String]$_.Id),$_.Name} -Type Process
                }
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-Process -Name "$Argument*" | Get-Unique | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Process
            }
        }
    }.GetNewClosure()
    
    $GetProcessHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Id' {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                if ($Argument -match '^[0-9]+$') {
                    Get-Process @Parameters | Where-Object {$_.Id.ToString() -like "$Argument*"} |
                        New-TabItem -Value {$_.Id} -Text {"{0,-4} <# {1} #>" -f ([String]$_.Id),$_.Name} -Type Process
                } else {
                    Get-Process @Parameters | Where-Object {$_.Name -like "$Argument*"} |
                        New-TabItem -Value {$_.Id} -Text {"{0,-4} <# {1} #>" -f ([String]$_.Id),$_.Name} -Type Process
                }
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Process -Name "$Argument*" @Parameters | Get-Unique | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Process
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Debug-Process" $ProcessHandler -Type "Command"
    Register-TabExpansion "Get-Process" $GetProcessHandler -Type "Command"
    Register-TabExpansion "Stop-Process" $ProcessHandler -Type "Command"
    Register-TabExpansion "Wait-Process" $ProcessHandler -Type "Command"
}

## PSBreakpoint
& {
    $PSBreakpointHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Breakpoint' {
                ## TODO:  More info in display text
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                $DisplayText = {
                    $Text = "{0,-2} " -f $_.Id
                    if ($_.Command) {
                        $Text += $_.Command
                        if ($_.Script) {
                            $Text += " ({0})" -f $_.Script
                        }
                    } elseif ($_.Variable) {
                        $Text += '$' + $_.Variable
                        if ($_.Script) {
                            $Text += " ({0})" -f $_.Script
                        }
                    } elseif ($_.Line) {
                        if ($_.Script.Length -ge 60) {
                            $Script = $_.Script.SubString(0, 60)
                        } else {
                            $Script = $_.Script
                        }
                        $Text += "{0}:{1}" -f $Script,$_.Line
                    }
                    $Text
                }
                Get-PSBreakpoint | Sort-Object Id | New-TabItem -Value {"(Get-PSBreakPoint -Id {0})" -f $_.Id} -Text $DisplayText -Type BreakPoint
            }
            'Command' {
                $TabExpansionHasOutput.Value = $true
                ## TODO:  Filter command list based on what is used in a script?!
                ## TODO:  Set object types
                $CommandTypes = "Function","ExternalScript","Filter","Cmdlet"
                if ($PSVersionTable.PSVersion -ge "3.0") {
                    $CommandTypes += "Workflow"
                }
                Get-Command "$Argument*" -CommandType $CommandTypes | New-TabItem -Value {$_.Name} -Text {$_.Name}
            }
            'Id' {
                ## TODO:  More info in display text
                $TabExpansionHasOutput.Value = $true
                $DisplayText = {
                    $Text = "{0,-2} " -f $_.Id
                    if ($_.Command) {
                        $Text += $_.Command
                        if ($_.Script) {
                            $Text += " ({0})" -f $_.Script
                        }
                    } elseif ($_.Variable) {
                        $Text += '$' + $_.Variable
                        if ($_.Script) {
                            $Text += " ({0})" -f $_.Script
                        }
                    } elseif ($_.Line) {
                        if ($_.Script.Length -ge 60) {
                            $Script = $_.Script.SubString(0, 60)
                        } else {
                            $Script = $_.Script
                        }
                        $Text += "{0}:{1}" -f $Script,$_.Line
                    }
                    $Text
                }
                Get-PSBreakpoint | Sort-Object Id | New-TabItem -Value {$_.Id} -Text $DisplayText -Type BreakPoint
            }
            'Line' {
                ## TODO:  Show line contents?
                $TabExpansionHasOutput.Value = $true
                if ($Context.OtherParameters["Script"]) {
                    1..(Get-Content (Resolve-TabExpansionParameterValue $Context.OtherParameters["Script"])).Count |
                        New-TabItem -Value {$_} -Text {$_}
                }
            }
            'Script' {
                ## TODO: Display relative paths
                $Scripts = Get-ChildItem "$Argument*" -Include *.ps1 | Select-Object -ExpandProperty FullName
                if ($Scripts) {
                    $TabExpansionHasOutput.Value = $true
                    $Scripts
                }
            }
            'Variable' {
                if ($Argument -notlike '$*') {
                    $TabExpansionHasOutput.Value = $true
                    Get-Variable "$Argument*" -Scope Global | Select-Object -ExpandProperty Name
                }
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Disable-PSBreakpoint" $PSBreakpointHandler -Type Command
    Register-TabExpansion "Enable-PSBreakpoint" $PSBreakpointHandler -Type Command
    Register-TabExpansion "Get-PSBreakpoint" $PSBreakpointHandler -Type Command
    Register-TabExpansion "Set-PSBreakpoint" $PSBreakpointHandler -Type Command
    Register-TabExpansion "Remove-PSBreakpoint" $PSBreakpointHandler -Type Command
}

## PSDrive
& {
    $PSDriveHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-PSDrive "$Argument*" | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    $NewPSDriveHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Scope' {
                $TabExpansionHasOutput.Value = $true
                "Global","Local","Script","0"
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Get-PSDrive" $PSDriveHandler -Type "Command"
    Register-TabExpansion "New-PSDrive" $NewPSDriveHandler -Type "Command"
    Register-TabExpansion "Remove-PSDrive" $PSDriveHandler -Type "Command"
}

## PSSession
& {
    $PSSessionHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'ConfigurationName' {
                ## TODO:  But can we?
            }
            'Id' {
                $TabExpansionHasOutput.Value = $true
                Get-PSSession | Select-Object -ExpandProperty Id
            }
            'InstanceId' {
                $TabExpansionHasOutput.Value = $true
                Get-PSSession | Where-Object {$_.InstanceId -like "$Argument*"} | Select-Object -ExpandProperty InstanceId
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-PSSession -Name "$Argument*" | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    $ImportPSSessionHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'CommandName' {
                ## TODO:
                ## TODO: [workitem:16]
            }
            'FormatTypeName' {
                ## TODO:
                ## TODO: [workitem:16]
            }
            'Module' {
                ## TODO: Grab from session instead?
                $TabExpansionHasOutput.Value = $true
                (Get-Module -ListAvailable "$Argument*") + (Get-PSSnapin "$Argument*") | Select-Object -ExpandProperty Name | Sort-Object
            }
            'Session' {
                if ($Argument -notlike '$*') {
                    $TabExpansionHasOutput.Value = $true
                    $QuoteSpaces.Value = $false
                    Get-PSSession -Name "$Argument*" | ForEach-Object {'(Get-PSSession -Name "{0}")' -f $_.Name}
                }
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Invoke-Command" $PSSessionHandler -Type "Command"  ## if we can get other parameters
    Register-TabExpansion "Enter-PSSession" $PSSessionHandler -Type "Command"
    Register-TabExpansion "Export-PSSession" $ImportPSSessionHandler -Type "Command"
    Register-TabExpansion "Get-PSSession" $PSSessionHandler -Type "Command"
    Register-TabExpansion "Import-PSSession" $ImportPSSessionHandler -Type "Command"
    Register-TabExpansion "Remove-PSSession" $PSSessionHandler -Type "Command"
}

## PSSessionConfiguration
& {
    $PSSessionConfigurationHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'ConfigurationTypeName' {
                ## TODO: Find way to differentiate namespaces from types
                $TabExpansionHasOutput.Value = $true
                $Dots = $Argument.Split(".").Count - 1
                $res = @()
                $res += $dsTabExpansionDatabase.Tables['Types'].Select("ns like '$Argument*' and dc = $($Dots + 1)") |
                    Select-Object -Unique -ExpandProperty ns
                if ($Dots -gt 0) {
                    $res += $dsTabExpansionDatabase.Tables['Types'].Select("name like '$Argument*' and dc = $Dots") |
                        Select-Object -ExpandProperty Name
                }
                $res
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-PSSessionConfiguration "$Argument*" | Select-Object -ExpandProperty Name
            }
        }
    }

    Register-TabExpansion "Disable-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
    Register-TabExpansion "Enable-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
    Register-TabExpansion "Get-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
    Register-TabExpansion "Register-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
    Register-TabExpansion "Set-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
    Register-TabExpansion "Unregister-PSSessionConfiguration" $PSSessionConfigurationHandler -Type "Command"
}

## Add-PSSnapin
Register-TabExpansion "Add-PSSnapin" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            $Loaded = @(Get-PSSnapin)
            Get-PSSnapin "$Argument*" -Registered | Where-Object {$Loaded -notcontains $_} |
                Select-Object -ExpandProperty Name | Sort-Object
        }
    }
}.GetNewClosure()

## Get-PSSnapin
Register-TabExpansion "Get-PSSnapin" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Name' {
            $TabExpansionHasOutput.Value = $true
            $Parameters = @{"ErrorAction" = "SilentlyContinue"}
            if ($Context.OtherParameters["Registered"]) {
                $Parameters["Registered"] = $true
            }
            Get-PSSnapin "$Argument*" @Parameters | Select-Object -ExpandProperty Name | Sort-Object
        }
    }
}.GetNewClosure()

## Service
& {
    $ServiceHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'DisplayName' {
                $TabExpansionHasOutput.Value = $true
                Get-Service -DisplayName "*$Argument*" | Select-Object -ExpandProperty DisplayName
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-Service -Name "$Argument*" | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    
    $GetServiceHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'DisplayName' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Service -DisplayName "*$Argument*" @Parameters | Select-Object -ExpandProperty DisplayName
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Service -Name "$Argument*" @Parameters | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    
    $SetServiceHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                $Parameters = @{}
                if ($Context.OtherParameters["ComputerName"]) {
                    $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                }
                Get-Service -Name "$Argument*" @Parameters | Select-Object -ExpandProperty Name
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Get-Service" $GetServiceHandler -Type "Command"
    Register-TabExpansion "Restart-Service" $ServiceHandler -Type "Command"
    Register-TabExpansion "Resume-Service" $ServiceHandler -Type "Command"
    Register-TabExpansion "Set-Service" $SetServiceHandler -Type "Command"
    Register-TabExpansion "Start-Service" $ServiceHandler -Type "Command"
    Register-TabExpansion "Stop-Service" $ServiceHandler -Type "Command"
    Register-TabExpansion "Suspend-Service" $ServiceHandler -Type "Command"
}

## Set-StrictMode
Register-TabExpansion "Set-StrictMode" -Type Command {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Version' {
            $TabExpansionHasOutput.Value = $true
            "1.0","2.0","Latest" | Where-Object {$_ -like "$Argument*"}
        }
    }
}.GetNewClosure()

## TraceSource
& {
    $TraceSourceHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-TraceSource "$Argument*" | Select-Object -ExpandProperty Name
            }
            'RemoveListener' {
                $TabExpansionHasOutput.Value = $true
                "Host","Debug","*" | Where-Object {$_ -like "$Argument*"}
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Get-TraceSource" $TraceSourceHandler -Type "Command"
    Register-TabExpansion "Set-TraceSource" $TraceSourceHandler -Type "Command"
    Register-TabExpansion "Trace-Command" $TraceSourceHandler -Type "Command"
}

## Get-Verb
Register-TabExpansion "Get-Verb" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'Verb' {
            $TabExpansionHasOutput.Value = $true
            Get-Verb "$Argument*" | Select-Object -ExpandProperty Verb | Sort-Object
        }
    }
}.GetNewClosure()

## Variable
& {
    $VariableHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                if ($Argument -notlike '$*') {
                    $TabExpansionHasOutput.Value = $true
                    Get-Variable "$Argument*" -Scope "Global" | Select-Object -ExpandProperty Name
                }
            }
            'Scope' {
                $TabExpansionHasOutput.Value = $true
                "Global","Local","Script" | Where-Object {$_ -like "$Argument*"}
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Clear-Variable" $VariableHandler -Type "Command"
    Register-TabExpansion "Get-Variable" $VariableHandler -Type "Command"
    Register-TabExpansion "Remove-Variable" $VariableHandler -Type "Command"
    Register-TabExpansion "Set-Variable" $VariableHandler -Type "Command"
}

## Get-WinEvent
Register-TabExpansion "Get-WinEvent" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    $Parameters = @{"ErrorAction" = "SilentlyContinue"}
    if ($Context.OtherParameters["ComputerName"]) {
        $Parameters["ComputerName"] = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
    }
    switch -exact ($Context.Parameter) {
        'FilterHashTable' {
            $TabExpansionHasOutput.Value = $true
            $QuoteSpaces.Value = $false
            '@{LogName="*"}'
            '@{ProviderName="*"}'
            '@{Keywords=""}'
            '@{ID=""}'
            '@{Level=""}'
        }
        'ListLog' {
            $TabExpansionHasOutput.Value = $true
            ## TODO: Make it easier to access detailed Microsoft-* logs?
            Get-WinEvent -ListLog "$Argument*" @Parameters | Select-Object -ExpandProperty LogName
        }
        'ListProvider' {
            $TabExpansionHasOutput.Value = $true
            Get-WinEvent -ListProvider "$Argument*" @Parameters | Select-Object -ExpandProperty Name #| Sort-Object
        }
        'LogName' {
            $TabExpansionHasOutput.Value = $true
            ## TODO: Make it easier to access detailed Microsoft-* logs?
            Get-WinEvent -ListLog "$Argument*" @Parameters | Select-Object -ExpandProperty LogName
        }
        'ProviderName' {
            $TabExpansionHasOutput.Value = $true
            Get-WinEvent -ListProvider "$Argument*" @Parameters | Select-Object -ExpandProperty Name #| Sort-Object
        }
    }
}.GetNewClosure()

## WMI
& {
    $WmiObjectHandler = {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Class' {
                $TabExpansionHasOutput.Value = $true
                ## TODO: escape special characters?
                Get-TabExpansion "$Argument*" WMI | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type WMIClass
            }
            'Locale' {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
                    Where-Object {$_.Name -like "$Argument*"} | Sort-Object -Property Name |
                        New-TabItem -Value {$_.LCID} -Text {$_.Name} -Type Locale
            }
            'Name' {
                $TabExpansionHasOutput.Value = $true
                if ($Context.OtherParameters["Class"]) {
                    $Class = [WmiClass](Resolve-TabExpansionParameterValue $Context.OtherParameters["Class"])
                } elseif ($Context.OtherParameters["Path"]) {
                    $Class = [WmiClass]((Resolve-TabExpansionParameterValue $Context.OtherParameters["Path"]) -replace '\.\w.+')
                } elseif ($Context.PositionalParameters[0]) {
                    $Class = [WmiClass](Resolve-TabExpansionParameterValue $Context.PositionalParameters[0])
                }
                if ($Class) {
                    $Class.Methods | Where-Object {$_.Name -like "$Argument*"} | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Method
                }
            }
            'Namespace' {
                $TabExpansionHasOutput.Value = $true
                if ($Argument -notlike "ROOT\*") {
                    $Argument = "ROOT\$Argument"
                }
                if ($Context.OtherParameters["ComputerName"]) {
                    $ComputerName = Resolve-TabExpansionParameterValue $Context.OtherParameters["ComputerName"]
                } else {
                    $ComputerName = "."
                }
                
                $ParentNamespace = $Argument -replace '\\[^\\]*$'
                $Namespaces = New-Object System.Management.ManagementClass "\\$ComputerName\${ParentNamespace}:__NAMESPACE"
                $Namespaces = foreach ($Namespace in $Namespaces.PSBase.GetInstances()) {"{0}\{1}" -f $Namespace.__NameSpace,$Namespace.Name}
                $Namespaces | Where-Object {$_ -like "$Argument*"} | Sort-Object | New-TabItem -Value {$_} -Text {$_} -Type WMINamespace
            }
            'Path' {
                ## TODO: ???
            }
            'Property' {
                $TabExpansionHasOutput.Value = $true
                if ($Context.OtherParameters["Class"]) {
                    $Class = [WmiClass](Resolve-TabExpansionParameterValue $Context.OtherParameters["Class"])
                } elseif ($Context.PositionalParameters[0]) {
                    $Class = [WmiClass](Resolve-TabExpansionParameterValue $Context.PositionalParameters[0])
                }
                if ($Class) {
                    $Class.Properties | Where-Object {$_.Name -like "$Argument*"} | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Property
                }
            }
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Get-WmiObject" $WmiObjectHandler -Type "Command"
    Register-TabExpansion "Invoke-WmiMethod" $WmiObjectHandler -Type "Command"
    Register-TabExpansion "Register-WmiEvent" $WmiObjectHandler -Type "Command"
    Register-TabExpansion "Remove-WmiObject" $WmiObjectHandler -Type "Command"
    Register-TabExpansion "Set-WmiInstance" $WmiObjectHandler -Type "Command"
}

## WSMan & WSManInstance & WSManAction
& {
    ## TODO: [workitem:18]
}

## Format-Custom
Register-TabExpansion "Format-Custom" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'GroupBy' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
            }
        }
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Expression={$_.}}'
                '@{Expression={$_.}; Depth=3}'
            }
        }
        'View' {
            ## TODO: Need to figure out what type of object will be coming in
            ## TODO: [workitem:19]
        }
    }
}.GetNewClosure()

## Format-List
Register-TabExpansion "Format-List" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'GroupBy' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
            }
        }
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
            }
        }
        'View' {
            ## TODO: Need to figure out what type of object will be coming in
            ## TODO: [workitem:19]
        }
    }
}.GetNewClosure()

## Format-Table
Register-TabExpansion "Format-Table" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'GroupBy' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
            }
        }
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
                '@{Name=""; Expression={$_.}; Width=9}'
                '@{Name=""; Expression={$_.}; Width=9; Alignment="Left"}'
                '@{Name=""; Expression={$_.}; Width=9; Alignment="Center"}'
                '@{Name=""; Expression={$_.}; Width=9; Alignment="Right"}'
            }
        }
        'View' {
            ## TODO: Need to figure out what type of object will be coming in
            ## TODO: [workitem:19]
        }
    }
}.GetNewClosure()

## Format-Wide
Register-TabExpansion "Format-Wide" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'GroupBy' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Name=""; Expression={$_.}}'
                '@{Name=""; Expression={$_.}; FormatString=""}'
            }
        }
        'Property' {
            if ($Argument -like "@*") {
                $TabExpansionHasOutput.Value = $true
                $QuoteSpaces.Value = $false
                '@{Expression={$_.}}'
                '@{Expression={$_.}; FormatString=""}'
            }
        }
        'View' {
            ## TODO: Need to figure out what type of object will be coming in
            ## TODO: [workitem:19]
        }
    }
}.GetNewClosure()

## Function
Register-TabExpansion "function" -Type "Command" {
    param($Context, [ref]$TabExpansionHasOutput)
    $Argument = $Context.Argument
    if ($Context.PositionalParameters -eq 0) {
        $TabExpansionHasOutput.Value = $true
        if ($Argument -match '^[a-zA-Z]*$') {
            Get-Verb "$Argument*" | Select-Object -ExpandProperty Verb | Sort-Object
        }
    }
}.GetNewClosure()


#########################
## Parameter handlers
#########################

## -ComputerName and -Server
& {
    $ComputerNameHandler =  {
        param($Argument, [ref]$TabExpansionHasOutput)
        if ($Argument -notmatch '^\$') {
            $TabExpansionHasOutput.Value = $true
            Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -Type Computer
        }
    }.GetNewClosure()

    Register-TabExpansion "ComputerName" $ComputerNameHandler -Type Parameter
    Register-TabExpansion "Server" $ComputerNameHandler -Type Parameter
}

## Parameters that take the name of a variable
& {
    $VariableHandler = {
        param($Argument, [ref]$TabExpansionHasOutput)
        if ($Argument -notlike '^\$') {
            $TabExpansionHasOutput.Value = $true
            Get-Variable "$Argument*" -Scope Global | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Variable
        }
    }.GetNewClosure()
    
    Register-TabExpansion "ErrorVariable" $VariableHandler -Type Parameter
    Register-TabExpansion "OutVariable" $VariableHandler -Type Parameter
    Register-TabExpansion "Variable" $VariableHandler -Type Parameter
    Register-TabExpansion "WarningVariable" $VariableHandler -Type Parameter
}

## Parameters that take the name of a culture
& {
    $CultureHandler = {
        param($Argument, [ref]$TabExpansionHasOutput)
        if ($Argument -notlike '^\$') {
            $TabExpansionHasOutput.Value = $true
            [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
                Where-Object {$_.Name -like "$Argument*"} | New-TabItem -Value {$_.Name} -Text {$_.Name} -Type Culture | Sort-Object Name
        }
    }.GetNewClosure()
    
    Register-TabExpansion "Culture" $CultureHandler -Type Parameter
    Register-TabExpansion "UICulture" $CultureHandler -Type Parameter
}

## -PSDrive
Register-TabExpansion "PSDrive" -Type Parameter {
    param($Argument, [ref]$TabExpansionHasOutput)
    if ($Argument -notlike '^\$') {
        $TabExpansionHasOutput.Value = $true
        Get-PSDrive "$Argument*" | Select-Object -ExpandProperty Name
    }
}.GetNewClosure()

## -PSProvider
Register-TabExpansion "PSProvider" -Type Parameter {
    param($Argument, [ref]$TabExpansionHasOutput)
    if ($Argument -notlike '^\$') {
        $TabExpansionHasOutput.Value = $true
        Get-PSProvider "$Argument*" | Select-Object -ExpandProperty Name
    }
}.GetNewClosure()


#########################
## Parameter Name handlers
#########################

## iexplore.exe
& {
    Register-TabExpansion iexplore.exe -Type ParameterName {
        param($Context, $Parameter)
        $Parameters = "-extoff","-embedding","-k","-nohome"
        $Parameters | Where-Object {$_ -like "$Parameter*"}
    }.GetNewClosure()

    Function iexploreexeparameters {
        param(
            [Switch]$extoff
            ,
            [Switch]$embedding
            ,
            [Switch]$k
            ,
            [Switch]$nohome
            ,
            [Parameter(Position = 0)]
            [String]$URL
        )
    }

    $IExploreCommandInfo = Get-Command iexploreexeparameters
    Register-TabExpansion iexplore.exe -Type CommandInfo {
        param($Context)
        $IExploreCommandInfo
    }.GetNewClosure()

    Register-TabExpansion iexplore.exe -Type Command {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'URL' {
                $Argument = [Regex]::Escape($Argument)
                $Favorites = Get-ChildItem "$env:USERPROFILE/Favorites/*" -Include *.url -Recurse
                $Favorites = $Favorites | Where-Object {($_.Name -match $Argument) -or ($_ | Select-String "^URL=.*$Argument")} |
                    New-TabItem -Value {($_ | Select-String "^URL=").Line -replace "^URL="} -Text {$_.Name -replace '\.url$'} -Type URL

                if ($Favorites) {
                    $TabExpansionHasOutput.Value = $true
                    $QuoteSpaces.Value = $false
                    $Favorites
                }
            }
        }
    }.GetNewClosure()
}

## powershell.exe
& {
    Register-TabExpansion powershell.exe -Type ParameterName {
        param($Context, $Parameter)
        $Parameters = "-Command","-EncodedCommand","-ExecutionPolicy","-File","-InputFormat","-NoExit","-NoLogo",
            "-NonInteractive","-NoProfile","-OutputFormat","-PSConsoleFile","-Sta","-Version","-WindowStyle"
        $Parameters | Where-Object {$_ -like "$Parameter*"}
        <#
        PowerShell[.exe] [-PSConsoleFile <file> | -Version <version>]
        [-NoLogo] [-NoExit] [-Sta] [-NoProfile] [-NonInteractive]
        [-InputFormat {Text | XML}] [-OutputFormat {Text | XML}]
        [-WindowStyle <style>] [-EncodedCommand <Base64EncodedCommand>]
        [-File <filePath> <args>] [-ExecutionPolicy <ExecutionPolicy>]
        [-Command { - | <script-block> [-args <arg-array>]
                      | <string> [<CommandParameters>] } ]
        #>
    }.GetNewClosure()

    Function powershellexeparameters {
        param(
            [String]$Command
            ,
            [String]$EncodedCommand
            ,
            [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy
            ,
            [String]$File
            ,
            [ValidateSet("Text","XML")]
            [String]$InputFormat
            ,
            [Switch]$NoExit
            ,
            [Switch]$NonInteractive
            ,
            [Switch]$NoLogo
            ,
            [Switch]$NoProfile
            ,
            [ValidateSet("Text","XML")]
            [String]$OutputFormat
            ,
            [String]$PSConsoleFile
            ,
            [Switch]$Sta
            ,
            [ValidateSet("1.0","2.0")]
            [String]$Version
            ,
            [ValidateSet("Normal","Minimized","Maximized","Hidden")]
            [String]$WindowStyle
        )
    }

    $PowershellCommandInfo = Get-Command powershellexeparameters
    Register-TabExpansion powershell.exe -Type CommandInfo {
        param($Context)
        $PowershellCommandInfo
    }.GetNewClosure()
}


#########################
## PowerTab function handlers
#########################

## Themes
& {
    $ThemeHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Name' {
                $TabExpansionHasOutput.Value = $true
                Get-ChildItem (Join-Path $PSScriptRoot "ColorThemes\Theme${Argument}*") -Include *.csv |
                    ForEach-Object {$_.Name -replace '^Theme([^\.]+)\.csv$','$1'}
            }
        }
    }

    Register-TabExpansion "Import-TabExpansionTheme" $ThemeHandler -Type Command
    Register-TabExpansion "Export-TabExpansionTheme" $ThemeHandler -Type Command
}

