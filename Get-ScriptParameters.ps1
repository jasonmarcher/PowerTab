Function global:Get-ScriptParameters ($path){
    if (!$path) {return}
    $sf = (gc $path) | out-String 
    $lf = $sf.Split("`n")
    $e = $lf.GetEnumerator()
    $morelines = $e.movenext()
    
    $Continue = $e.Current -match "(^\s*param\s*\(|^\s*#|)(.*)"
    if ($e.Current -match "^\s+$") {$Continue = $true}
    while ($continue -and $Morelines) { 
        $params = $matches[2] |? {$_}|% {$_.Split(',')}
        if ($Matches[1] -match 'param') {
            $level = 1
            while ($continue -and $morelines) {        
                
                $params | foreach {
                    [string]::join('',($_.getEnumerator() |% {
                        if ($_ -eq ')'){$level--}
                        elseif($_ -eq '('){$level++}
                        if ($level -eq 0) {$continue = $false}
                        if ($continue) {$_}
                    })).split('$')[1] |? {$_}|% {$_.split('=')[0]} |% {$_.replace(')','').trim()}
                    if (!$continue){break}
                }
                if ( $Continue ) {
                    $morelines = $e.movenext()
                    $params = $e.Current.Split(',')
                }
            }
        } else {
            $morelines = $e.MoveNext()
            $Continue = $e.Current -match "(^\s*param\s*\(|^\s*#)(.*)"
            if ($e.Current -match "^\s+$") {$Continue = $true}
        }
    }
}
    