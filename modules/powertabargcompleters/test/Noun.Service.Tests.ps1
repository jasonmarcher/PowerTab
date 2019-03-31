. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Service.ps1"

$MockObjects = @{Name = "Foo"; DisplayName = "Foo"}, @{Name = "Bar"; DisplayName = "Bar"},
    @{Name = "FooBar"; DisplayName = "FooBar"}, @{Name = "Scooby"; DisplayName = "Scooby"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Service" {
    Mock Get-Service {
        param(
            $Name,
            $DisplayName
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }
        if ($DisplayName) {
            $MockObjects = $MockObjects | Where-Object {$_.DisplayName -like "*$DisplayName*"}
        }

        $MockObjects
    }

    Context "ServiceDisplayName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_ServiceDisplayName

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'Foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_ServiceDisplayName -wordToComplete "Foo"

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name 'ob', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_ServiceDisplayName -wordToComplete "ob"

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }

    Context "ServiceName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_ServiceName

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'Foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_ServiceName -wordToComplete "Foo"

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*Bar', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_ServiceName -wordToComplete "*Bar"

            Assert-MockCalled Get-Service -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}