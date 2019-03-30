. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Version.ps1"

Describe -Tag "Unit" "Unit-Noun.Version" {
    Context "StrictVersion" {
        It "given No Arguments, it should return 3 Items" {
            $Results = Invoke-Handler $Completion_StrictVersion

            $Results.Count | Should -Be 3
        }

        It "given a Version '1', it should return 1 Item" {
            $Results = Invoke-Handler $Completion_StrictVersion -wordToComplete "1"

            $Results.Count | Should -Be 1
        }
    }
}