. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Alias.ps1"

$MockObjects = @{Name = "foo"}, @{Name = "bar"},
    @{Name = "cat"}, @{Name = "dir"},
    @{Name = "dag"},@{Name = "foobar"},
    @{Name = "foobarBaz"} | ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Alias" {
    Mock Get-Alias {
        param(
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "AliasName" {
        It "given No Arguments, it should return 7 Items" {
            $Results = Invoke-Handler $Completion_AliasName

            Assert-MockCalled Get-Alias -Exactly 1 -Scope It
            $Results.Count | Should -Be 7
        }

        It "given a Name 'c', it should return 1 Item" {
            $Results = Invoke-Handler $Completion_AliasName -wordToComplete "c"

            Assert-MockCalled Get-Alias -Exactly 1 -Scope It
            $Results.Count | Should -Be 1
        }

        It "given a Name '*bar', it should return 3 Items" {
            $Results = Invoke-Handler $Completion_AliasName -wordToComplete "*bar"

            Assert-MockCalled Get-Alias -Exactly 1 -Scope It
            $Results.Count | Should -Be 3
        }
    }
}