. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Param.Scope.ps1"

Describe -Tag "Unit" "Unit-Param.Scope" {
    Context "ParamScope" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_ParamScope

            $Results.Count | Should -Be 4
        }

        It "given a Scope 'Global', it should return 1 Item" {
            $Results = Invoke-Handler $Completion_ParamScope -wordToComplete "Global"

            $Results.Count | Should -Be 1
        }
    }
}