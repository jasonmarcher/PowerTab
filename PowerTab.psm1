
$isSetupAlreadyRun =  Test-Path $home\Documents\WindowsPowerShell\PowerTabConfig.xml
if (-not $isSetupAlreadyRun)
{
    #First run - do setup. 
    & $psScriptRoot\PowerTabSetup.ps1 $psScriptRoot
    
}

& $psScriptRoot\Init-TabExpansion.ps1 -ConfigurationLocation $home\Documents\WindowsPowerShell
