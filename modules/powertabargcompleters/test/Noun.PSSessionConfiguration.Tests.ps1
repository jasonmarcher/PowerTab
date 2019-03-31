. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.PSSessionConfiguration.ps1"

$MockObjects = @{Name = "Foo"}, @{Name = "Bar"}, @{Name = "FooBar"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.PSSessionConfiguration" {
    Mock Get-PSSessionConfiguration {
        param(
            [Parameter(Position = 0)]
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "PSSessionConfigurationName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_PSSessionConfigurationName

            Assert-MockCalled Get-PSSessionConfiguration -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'Foo', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_PSSessionConfigurationName -wordToComplete "Foo"

            Assert-MockCalled Get-PSSessionConfiguration -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*Bar', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_PSSessionConfigurationName -wordToComplete "*Bar"

            Assert-MockCalled Get-PSSessionConfiguration -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}