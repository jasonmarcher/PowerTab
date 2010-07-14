## Robocopy
& {
    Register-TabExpansion "robocopy.exe" -Type "Command" {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Options' {
                $TabExpansionHasOutput.Value = $true
                if ($Argument -notlike "/*") {$Argument = "/$Argument"}
                $RoboHelp = robocopy.exe /? | Select-String '::'
                $r = [regex]'(.*)::(.*)'
                $RoboHelpObject = $RoboHelp | Select-Object `
                    @{Name='Parameter';Expression={$r.Match($_).Groups[1].Value.Trim()}},
                    @{Name='Description';Expression={$r.Match($_).Groups[2].Value.Trim()}}

                <# ## For now, we don't need category
                $RoboHelpObject = $RoboHelpObject | ForEach-Object {$Cat = 'General'} {
                    if ($_.Parameter -eq '') {
                        if ($_.Description -ne '') {$cat = $_.Description -replace 'options :',''}
                    } else {
                        $_ | Select-Object @{Name='Category';Expression={$cat}},Parameter,Description
                    }
                }
                #>
                $RoboHelpObject | Where-Object {$_.Parameter -like "$Argument*"} | Select-Object -ExpandProperty Parameter
            }
        }
    }.GetNewClosure()

    Function robocopyexeparameters {
        param(
            [Parameter(Position = 0)]
            [String]$Source
            ,
            [Parameter(Position = 1)]
            [String]$Destination
            ,
            [Parameter(Position = 2, ValueFromRemainingArguments = $true)]
            [String[]]$Options
        )
    }

    $RobocopyCommandInfo = Get-Command "robocopyexeparameters"
    Register-TabExpansion "robocopy.exe" -Type "CommandInfo" {
        param($Context)
        $RobocopyCommandInfo
    }.GetNewClosure()
}

## xcopy
& {
    Register-TabExpansion "xcopy.exe" -Type "Command" {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Options' {
                $TabExpansionHasOutput.Value = $true
                if ($Argument -notlike "/*") {$Argument = "/$Argument"}
                $r = [regex]'^\s\s(/\S+)*'
                xcopy.exe /? | ForEach-Object {$r.Match($_).Groups[1].Value.Trim()} | Where-Object {$_ -like "$Argument*"}
            }
        }
    }.GetNewClosure()

    Function xcopyexeparameters {
        param(
            [Parameter(Position = 0)]
            [String]$Source
            ,
            [Parameter(Position = 1)]
            [String]$Destination
            ,
            [Parameter(Position = 2, ValueFromRemainingArguments = $true)]
            [String[]]$Options
        )
    }

    $xcopyCommandInfo = Get-Command "xcopyexeparameters"
    Register-TabExpansion "xcopy.exe" -Type "CommandInfo" {
        param($Context)
        $xcopyCommandInfo
    }.GetNewClosure()
}

## cmdkey