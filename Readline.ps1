# Readline.ps1
#
# 


Function Show-CommonPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [String]
        $LastWord = ''
        ,
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object[]]
        $InputObject = @()
    )

    begin {
        [Object[]]$Content = @()
    }

    process {
        $Content += $InputObject
    }

    end {
        if ($Content.Count -le 1) {
            $Content | Select-Object -ExpandProperty Value
        } else {
            $CommonPrefix = Search-CommonPrefix ($Content | Select-Object -ExpandProperty Value)

            if ($CommonPrefix) {
                if ($LastWord -eq $CommonPrefix) {
                    [System.Console]::Beep()
                }
                $CommonPrefix
            } else {
                [System.Console]::Beep()
            }
        }
    }
}


Function Search-CommonPrefix {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNull()]
        [String[]]
        $Strings = @()
    )

    end {
        if ($Strings.Count -eq 0) {
            return ""
        }
        if ($Strings.Count -eq 1) {
            return $Strings[0]
        }

        $PrefixLength = 0

        :outerloop foreach ($Character in $Strings[0].ToCharArray()) {
            foreach ($String in $Strings) {
                if (($String.Length -le $PrefixLength) -or ($String[$PrefixLength] -ne $Character)) {
                    break outerloop
                }
            }
            $PrefixLength++
        }

        $Strings[0].Substring(0, $PrefixLength)
    }
}
