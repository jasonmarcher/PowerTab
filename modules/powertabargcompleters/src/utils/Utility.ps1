Function NewTabItem {
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


Function RegisterArgumentCompleter {
    param(
        [String]
        $CommandName
        ,
        [String]
        $ParameterName
        ,
        [ScriptBlock]
        $ScriptBlock
    )

    if ($PSVersionTable.PSVersion -ge "5.0") {
        if ($CommandName -and $ParameterName) {
            Register-ArgumentCompleter -CommandName $CommandName -ParameterName $ParameterName -ScriptBlock $ScriptBlock
        } elseif ($CommandName) {
            Register-ArgumentCompleter -CommandName $CommandName -ScriptBlock $ScriptBlock
        } else {
            Register-ArgumentCompleter -ParameterName $ParameterName -ScriptBlock $ScriptBlock
        }
    } else {
        if (-not $global:options) { $global:options = @{CustomArgumentCompleters = @{};NativeArgumentCompleters = @{}}}

        if ($CommandName -and $ParameterName) {
            $global:options['CustomArgumentCompleters']["${CommandName}:$ParameterName"] = $ScriptBlock
        } elseif ($CommandName) {
            $global:options['CustomArgumentCompleters'][$CommandName] = $ScriptBlock
        } else {
            $global:options['CustomArgumentCompleters'][$ParameterName] = $ScriptBlock
        }
    }
}

Function FindModule {
    [CmdletBinding()]
    param(
        [String[]]$Name = "*"
        ,
        [Switch]$All
    )

    foreach ($n in $Name) {
        $folder = [System.IO.Path]::GetDirectoryName($n)
        $n = [System.IO.Path]::GetFileName($n)
        $ModulePaths = $Env:PSModulePath -split ";" | Select-Object -Unique | Where-Object {Test-Path $_}

        if ($folder) {
            $ModulePaths = $ModulePaths | ForEach-Object {Join-Path $_ $folder}
        }

        # Note: the order of these is important. They need to be in the order they'd be loaded by the system
        $Files = @(Get-ChildItem -Path $ModulePaths -Recurse -Filter "$n.ps?1" -EA 0; Get-ChildItem -Path $ModulePaths -Recurse -Filter "$n.dll" -EA 0)
        $Files | Where-Object {
                $parent = [System.IO.Path]::GetFileName( $_.PSParentPath )
                return $all -or ($parent -eq $_.BaseName) -or ($folder -and ($parent -eq ([System.IO.Path]::GetFileName($folder))) -and ($n -eq $_.BaseName))
            } | Group-Object PSParentPath | . {process{@($_.Group)[0]}}

        # TODO: Search installed modules as well.

        # Possibly useful in the future
        # | Sort-Object {switch ($_.Extension) {".psd1"{1} ".psm1"{2}}})
    }
}