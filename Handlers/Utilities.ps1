
## netsh
& {
    Register-TabExpansion netsh.exe -Type Command {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'r' {
                $TabExpansionHasOutput.Value = $true
                Get-TabExpansion "$Argument*" Computer | New-TabItem -Value {$_.Text} -Text {$_.Text} -Type Computer
            }
        }
    }.GetNewClosure()

    Function netshexeparameters {
        param(
            [String]$a
            ,
            [ValidateSet("advfirewall","branchcache","bridge","dhcpclient","dnsclient","firewall","http","interface","ipsec",
                "lan","mbn","namespace","nap","netio","p2p","ras","rpc","trace","wcn","wfp","winhttp","winsock","wlan")]
            [String]$c
            ,
            [String]$r
            ,
            [String]$u
            ,
            [String]$p
            ,
            [String]$f
            ,
            [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
            [String[]]$Commands
        )
    }

    ## TODO: Handle commands and contexts

    $netshCommandInfo = Get-Command netshexeparameters
    Register-TabExpansion netsh.exe -Type CommandInfo {
        param($Context)
        $netshCommandInfo
    }.GetNewClosure()

    Register-TabExpansion netsh.exe -Type ParameterName {
        param($Context, $Parameter)
        $Parameters = "-a","-c","-r","-u","-p","-f"
        $Parameters | Where-Object {$_ -like "$Parameter*"}
    }.GetNewClosure()
}

## reg
& {
    Register-TabExpansion reg.exe -Type Command {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        <#
        switch -exact ($Context.Parameter) {
            'r' {
                $TabExpansionHasOutput.Value = $true
                Get-TabExpansion "$Argument*" Computer | New-TabItem {$_.Text} {$_.Text} -Type Computer
            }
        }
        #>
    }.GetNewClosure()

    Function regexeparameters {
        param(
            [Parameter(Position = 0)]
            [ValidateSet("QUERY","ADD","DELETE","COPY","SAVE","RESTORE","LOAD","UNLOAD","COMPARE","EXPORT","IMPORT","FLAGS")]
            [String]$Command
        )
    }

    ## TODO: Handle options

    $regCommandInfo = Get-Command regexeparameters
    Register-TabExpansion reg.exe -Type CommandInfo {
        param($Context)
        $regCommandInfo
    }.GetNewClosure()
}
