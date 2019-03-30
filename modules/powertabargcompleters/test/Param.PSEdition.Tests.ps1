. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Param.PSEdition.ps1"

Describe -Tag "Unit" "Unit-Param.PSEdition" {
    Context "PSEdition" {
        It "given No Arguments, it should return 2 Items" {
            $Results = Invoke-Handler $Completion_PSEdition

            $Results.Count | Should -Be 2
        }
    }
}