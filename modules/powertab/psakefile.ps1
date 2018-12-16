Properties {
    $ModuleName = 'PowerTab'
    $RootDirectory = "$PSScriptRoot/../.."
    $SrcDirectory = "$PSScriptRoot/src"
    $HelpDirectory = "$PSScriptRoot/help"
    $OutputDirectory = "$RootDirectory/build/$ModuleName"
    $ReportDirectory = "$RootDirectory/build/reports"
    $DeployDirectory = "$HOME/Documents/WindowsPowerShell/Modules/$ModuleName"
}

Task 'default' -Depends build

Task 'clean' {
    if (Test-Path $OutputDirectory) {
        Remove-Item $OutputDirectory -Recurse -Force
    }
}

Task 'build' -Depends clean {
    New-Item $OutputDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    ## Copy manifest
    Copy-Item "$SrcDirectory/$ModuleName.psd1" -Destination $OutputDirectory -Force

    ## Build module
    Copy-Item "$SrcDirectory/$ModuleName.psm1" -Destination $OutputDirectory -Force
    Get-ChildItem "$SrcDirectory/*" -Include '*.ps1' -Recurse | Copy-Item -Destination $OutputDirectory -Force
    $ModuleContent = @(
        '## Reason: Using Write-Host is intentional',
        '[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]',
        '## Reason: ConsoleList uses variables that are intended to be used in recursive calls',
        '[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]',
        'param()'
    )
    foreach ($script in (Get-ChildItem "$SrcDirectory/*" -Include '*.ps1')) {
        $ModuleContent += Get-Content $script.FullName
    }
    foreach ($script in (Get-ChildItem "$SrcDirectory/handlers" -Include '*.ps1')) {
        $ModuleContent += Get-Content $script.FullName
    }
    $ModuleContent += Get-Content "$SrcDirectory/$ModuleName.psm1"
    # Set-Content "$OutputDirectory/$ModuleName.txt" -Value $ModuleContent -Encoding UTF8 -Force

    ## Copy resources
    Copy-Item "$SrcDirectory/res/*" -Destination $OutputDirectory -Recurse -Force

    ## Copy help
    Copy-Item "$HelpDirectory/*" -Include "about_*.txt" -Destination $OutputDirectory -Force
}

Task 'deploy' -Depends build {
    if (Test-Path $DeployDirectory) {
        Remove-Item $DeployDirectory -Recurse -Force
    }

    New-Item $DeployDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    Copy-Item "$OutputDirectory/*" -Destination $DeployDirectory -Recurse -Force
}

Task 'checkStyle' -Depends build {
    New-Item $ReportDirectory -ItemType Directory -ErrorAction SilentlyContinue > $null

    $FilesToCheck = Get-ChildItem $SrcDirectory -Include *.ps1 -Recurse
    $FilesToCheck += Get-ChildItem $OutputDirectory -Include *.psd1 -Recurse

    $Results = $FilesToCheck | ForEach-Object {Invoke-ScriptAnalyzer $_.FullName}
    $Results | Where-Object Severity -eq "Error" | Format-Table | Out-String | Write-Host -ForegroundColor Red
    $Results | Select-Object RuleName,Severity,Line,Column,ScriptName,Message | ConvertTo-Csv -NoTypeInformation | Set-Content "$ReportDirectory/checkstyle.csv" -Force
}