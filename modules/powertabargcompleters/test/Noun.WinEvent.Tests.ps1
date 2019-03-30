. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.WinEvent.ps1"

Describe -Tag "Unit" "Unit-Noun.WinEvent" {
    Context "WinEventFilterHashTable" {
        It "given No Arguments, it should return 5 Items" {
            $Results = Invoke-Handler $Completion_WinEventFilterHashTable

            $Results.Count | Should -Be 5
        }
    }
}