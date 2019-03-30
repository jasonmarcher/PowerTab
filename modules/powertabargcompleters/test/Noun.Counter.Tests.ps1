. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Counter.ps1"

Describe -Tag "Unit" "Unit-Noun.Counter" {
    Context "CounterFormat" {
        It "given No Arguments, it should return 3 Items" {
            $Results = Invoke-Handler $Completion_CounterFormat

            $Results.Count | Should -Be 3
        }
    }
}