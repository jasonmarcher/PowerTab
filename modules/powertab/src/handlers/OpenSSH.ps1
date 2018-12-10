
if ("OpenSSH for Windows" -eq (Get-Command ssh -ErrorAction SilentlyContinue).FileVersionInfo.ProductName) {
    ## SSH
    & {
        Register-TabExpansion "ssh.exe" -Type "Command" {
            param($Context, [ref]$TabExpansionHasOutput)
            $Argument = $Context.Argument
            switch -exact ($Context.Parameter) {
                'B' {
                    $TabExpansionHasOutput.Value = $true
                    Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
                'J' {
                    $TabExpansionHasOutput.Value = $true
                    Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
                'L' {
                    ## TODO: This is quick and dirty, needs to also support sockets
                    $TabExpansionHasOutput.Value = $true
                    Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
                'O' {
                    $TabExpansionHasOutput.Value = $true
                    $Commands = "check","forward","cancel","exit","stop"
                    $Commands | Where-Object {$_ -like "$Argument*"} | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
                'o' {
                    ## TODO: Options
                }
                'R' {
                    ## TODO: This is quick and dirty, needs to also support sockets
                    $TabExpansionHasOutput.Value = $true
                    Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
                'Destination' {
                    $TabExpansionHasOutput.Value = $true
                    $User = ""
                    if ($Argument -match '@') {
                        $User,$Argument = $Argument -split '@'
                        $User += '@'
                    }
                    Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$User + $_.Text} -Text {$_.Text} -ResultType ParameterValue
                }
            }
        }.GetNewClosure()

        Function sshexeparameters {
            param(
                [Parameter(Position = 0)]
                [String]$Destination
            )
            ## TODO:  Need to identify switch parameters
        }
        $SSHCommandInfo = Get-Command "sshexeparameters"
        Register-TabExpansion "ssh.exe" -Type "CommandInfo" {
            param($Context)
            $SSHCommandInfo
        }.GetNewClosure()

        Register-TabExpansion "ssh.exe" -Type "ParameterName" {
            param($Context, $Parameter)
            $Parameters = @(
                "-4",
                "-6",
                "-A",
                "-a",
                "-B",
                "-b",
                "-C",
                "-c",
                "-D",
                "-E",
                "-e",
                "-F",
                "-f",
                "-G",
                "-g",
                "-I",
                "-i",
                "-J",
                "-K",
                "-k",
                "-L",
                "-l",
                "-M",
                "-m",
                "-N",
                "-n",
                "-O",
                "-o",
                "-p",
                "-Q",
                "-q",
                "-R",
                "-S",
                "-s",
                "-T",
                "-t",
                "-V",
                "-v",
                "-W",
                "-w",
                "-X",
                "-x",
                "-Y",
                "-y"
            )
            $Parameters | Where-Object {$_ -like "$Parameter*"} | New-TabItem -Value {$_} -Text {$_} -ResultType ParameterName
        }.GetNewClosure()

        Function scpexeparameters {
            param(
                [Parameter(Position = 0)]
                [String]$Source
                ,
                [Parameter(Position = 1)]
                [String]$Destination
            )
            ## TODO:  Need to identify switch parameters
        }
        $SCPCommandInfo = Get-Command "scpexeparameters"
        Register-TabExpansion "scp.exe" -Type "CommandInfo" {
            param($Context)
            $SCPCommandInfo
        }.GetNewClosure()

        Register-TabExpansion "scp.exe" -Type "ParameterName" {
            param($Context, $Parameter)
            $Parameters = @(
                "-3",
                "-4",
                "-6",
                "-B",
                "-C",
                "-c",
                "-F",
                "-i",
                "-l",
                "-o",
                "-P",
                "-p",
                "-q",
                "-r",
                "-S",
                "-v"
            )
            $Parameters | Where-Object {$_ -like "$Parameter*"} | New-TabItem -Value {$_} -Text {$_} -ResultType ParameterName
        }.GetNewClosure()
    }
}