. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.PSSession.ps1"

$MockObjects = @{Id = 1; InstanceId = 1; Name = "Foo"}, @{Id = 2; InstanceId = 2; Name = "Bar"},
    @{Id = 3; InstanceId = 3; Name = "FooBar"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.PSSession" {
    Mock Get-PSSession {
        param(
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "PSSessionId" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_PSSessionId

            Assert-MockCalled Get-PSSession -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }
    }

    Context "PSSessionInstanceId" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_PSSessionInstanceId

            Assert-MockCalled Get-PSSession -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }
    }

    Context "PSSessionName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_PSSessionName

            Assert-MockCalled Get-PSSession -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'Foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_PSSessionName -wordToComplete "Foo"

            Assert-MockCalled Get-PSSession -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*Bar', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_PSSessionName -wordToComplete "*Bar"

            Assert-MockCalled Get-PSSession -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}