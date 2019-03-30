Properties {
    $ModuleName = 'PowerTabArgCompleters'
    $RootDirectory = "$PSScriptRoot/../.."
    $HelpDirectory = "$PSScriptRoot/help"
    $SrcDirectory = "$PSScriptRoot/src"
    $TestDirectory = "$PSScriptRoot/test"
    $OutputDirectory = "$RootDirectory/build/$ModuleName"
    $ReportDirectory = "$RootDirectory/build/reports/$ModuleName"
    $DeployDirectory = "$HOME/Documents/WindowsPowerShell/Modules/$ModuleName"
}

Task 'default' -Depends build

Task 'clean' {
    if (Test-Path $OutputDirectory) {
        Remove-Item $OutputDirectory -Recurse -Force
    }
}

Task 'buildHelp' {
    # New-Item $OutputDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    # New-ExternalHelp -Path $HelpDirectory -OutputPath $OutputDirectory

    # ## Copy about topics
    # Copy-Item "$HelpDirectory/*" -Include "about_*.txt" -Destination $OutputDirectory -Force
}

Task 'build' -Depends buildHelp {
    New-Item $OutputDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    ## Copy manifest
    Copy-Item "$SrcDirectory/$ModuleName.psd1" -Destination $OutputDirectory -Force

    ## Build module
    $ModuleContent = @(
        'using namespace System.Management.Automation',
        'param()'
    )
    foreach ($script in (Get-ChildItem "$SrcDirectory/utils" -Include '*.ps1' -Recurse)) {
        $ModuleContent += Get-Content $script.FullName
    }
    foreach ($script in (Get-ChildItem "$SrcDirectory/completers" -Include '*.ps1' -Recurse)) {
        $ModuleContent += Get-Content $script.FullName
    }
    # $ModuleContent += Get-Content "$SrcDirectory/$ModuleName.psm1"
    Set-Content "$OutputDirectory/$ModuleName.psm1" -Value $ModuleContent -Encoding UTF8 -Force

    ## Copy resources
    # Copy-Item "$SrcDirectory/res/*" -Destination $OutputDirectory -Recurse -Force
}

Task 'deploy' {
    if (Test-Path $DeployDirectory) {
        Remove-Item $DeployDirectory -Recurse -Force
    }

    New-Item $DeployDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    Copy-Item "$OutputDirectory/*" -Destination $DeployDirectory -Recurse -Force
}

Task 'checkStyle' {
    New-Item $ReportDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    $FilesToCheck = Get-ChildItem $SrcDirectory -Include *.ps1 -Recurse
    $FilesToCheck += Get-ChildItem $OutputDirectory -Include *.psd1 -Recurse

    $Results = $FilesToCheck | ForEach-Object {Invoke-ScriptAnalyzer $_.FullName}
    $Results | Where-Object Severity -eq "Error" | Format-Table | Out-String | Write-Host -ForegroundColor Red
    $Results | Select-Object RuleName,Severity,Line,Column,ScriptName,Message | ConvertTo-Csv -NoTypeInformation | Set-Content "$ReportDirectory/checkstyle.csv" -Force
}

Task 'test' {
    New-Item $ReportDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    Invoke-Pester `
        -OutputFile "$ReportDirectory/tests_unit.xml" -CodeCoverage "$SrcDirectory/completers/*.ps1" -CodeCoverageOutputFile "$ReportDirectory/coverage.xml" 
}