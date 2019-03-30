. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Param.Culture.ps1"

Describe -Tag "Unit" "Unit-Param.Culture" {
    Context "Culture" {
        It "given No Arguments, it should return all Cultures" {
            $Results = Invoke-Handler $Completion_Culture

            $AllCultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures)

            $Results.Count | Should -Be $AllCultures.Count
        }
    }

    Context "GeoId" {
        It "given No Arguments, it should return all GeoIds" {
            $Results = Invoke-Handler $Completion_Geoid

            $AllGeoIds = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures) |
                ForEach-Object {try{[System.Globalization.RegionInfo]$_.Name}catch{}} | Select-Object -Unique

            $Results.Count | Should -Be $AllGeoIds.Count
        }
    }

    Context "Locale" {
        It "given No Arguments, it should return all Locales" {
            $Results = Invoke-Handler $Completion_Locale

            $AllLocales = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures)

            $Results.Count | Should -Be $AllLocales.Count
        }
    }
}