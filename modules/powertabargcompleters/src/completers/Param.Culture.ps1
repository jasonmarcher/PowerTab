$Completion_Culture = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
        Where-Object {$_.Name -like "$wordToComplete*"} | Sort-Object Name | NewTabItem -Value {$_.Name} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -ParameterName "Culture" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -ParameterName "UICulture" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -ParameterName "CultureInfo" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -CommandName "New-WinUserLanguageList" -ParameterName "Language" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -CommandName "Set-WinSystemLocale" -ParameterName "SystemLocale" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -CommandName "Set-WinUILanguageOverride" -ParameterName "Language" -ScriptBlock $Completion_Culture
RegisterArgumentCompleter -CommandName "Set-WinUserLanguageList" -ParameterName "LanguageList" -ScriptBlock $Completion_Culture

$Completion_Geoid = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
        ForEach-Object {try{[System.Globalization.RegionInfo]$_.Name}catch{}} | Where-Object {$_.DisplayName -like "$wordToComplete*"} |
        Select-Object -Unique | NewTabItem -Value {$_.GeoId} -Text {$_.DisplayName} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Set-WinHomeLocation" -ParameterName "GeoId" -ScriptBlock $Completion_Geoid

$Completion_Locale = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
        Where-Object {$_.Name -like "$wordToComplete*"} | Sort-Object -Property Name | Select-Object LCID, Name |
        ForEach-Object {if ($_.LCID -eq 127) {$_.Name = "Invariant Language"}; $_} |
        NewTabItem -Value {$_.LCID} -Text {$_.Name} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "Get-WmiObject" -ParameterName "Locale" -ScriptBlock $Completion_Locale
RegisterArgumentCompleter -CommandName "Invoke-WmiMethod" -ParameterName "Locale" -ScriptBlock $Completion_Locale
RegisterArgumentCompleter -CommandName "New-MarkdownHelp" -ParameterName "Locale" -ScriptBlock $Completion_Locale
RegisterArgumentCompleter -CommandName "Remove-WmiObject" -ParameterName "Locale" -ScriptBlock $Completion_Locale
RegisterArgumentCompleter -CommandName "Set-WmiInstance" -ParameterName "Locale" -ScriptBlock $Completion_Locale