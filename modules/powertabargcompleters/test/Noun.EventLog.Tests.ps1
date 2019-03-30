. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.EventLog.ps1"

Describe -Tag "Unit" "Unit-Noun.EventLog" {
    Context "EventLogCategory" {
        It "given No Arguments, it should return 8 Items" {
            $Results = Invoke-Handler $Completion_EventLogCategory

            $Results.Count | Should -Be 8
        }

        It "given a Name 'S', it should return 3 Items" {
            $Results = Invoke-Handler $Completion_EventLogCategory -wordToComplete "S"

            $Results.Count | Should -Be 3
        }
    }
}