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

    Context "EventLogLogName" {
        $MockObjects = "foo", "bar", "foobar"

        Mock Get-EventLog {
            param(
                [Switch]$List,
                [Switch]$PSProvider
            )

            $MockObjects
        }

        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_EventLogLogName

            Assert-MockCalled Get-EventLog -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_EventLogLogName -wordToComplete "foo"

            Assert-MockCalled Get-EventLog -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*bar', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_EventLogLogName -wordToComplete "*bar"

            Assert-MockCalled Get-EventLog -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}