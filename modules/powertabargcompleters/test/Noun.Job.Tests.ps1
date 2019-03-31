. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Job.ps1"

$MockObjects = @{Id = 1; InstanceId = 1; Name = "Foo"}, @{Id = 2; InstanceId = 2; Name = "Bar"},
    @{Id = 3; InstanceId = 3; Name = "FooBar"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Job" {
    Mock Get-Job {
        param(
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "JobId" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_JobId

            Assert-MockCalled Get-Job -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }
    }

    Context "JobInstanceId" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_JobInstanceId

            Assert-MockCalled Get-Job -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }
    }

    Context "JobName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_JobName

            Assert-MockCalled Get-Job -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'Foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_JobName -wordToComplete "Foo"

            Assert-MockCalled Get-Job -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*Bar', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_JobName -wordToComplete "*Bar"

            Assert-MockCalled Get-Job -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}