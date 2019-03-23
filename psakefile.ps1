Properties {
    $ModuleName = 'PowerTab'
    $SrcDirectory = "$PSScriptRoot/src"
    $OutputDirectory = "$PSScriptRoot/build"
    $ReportDirectory = "$OutputDirectory/reports"
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

    Invoke-psake -buildFile modules/powertab/psakefile.ps1 -taskList 'build'
    Invoke-psake -buildFile modules/powertabargcompleters/psakefile.ps1 -taskList 'build'
}

Task 'deploy' -Depends build {
    Invoke-psake -buildFile modules/powertab/psakefile.ps1 -taskList 'deploy'
    Invoke-psake -buildFile modules/powertabargcompleters/psakefile.ps1 -taskList 'deploy'
}

Task 'checkStyle' -Depends build {
    Invoke-psake -buildFile modules/powertab/psakefile.ps1 -taskList 'checkStyle'
    Invoke-psake -buildFile modules/powertabargcompleters/psakefile.ps1 -taskList 'checkStyle'
}