. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.PSDrive.ps1"

$MockObjects = @{Name = "foo"}, @{Name = "bar"}, @{Name = "foobar"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.PSDrive" {
    Mock Get-PSDrive {
        param(
            [Parameter(Position = 0)]
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "PSDriveName" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_PSDriveName

            Assert-MockCalled Get-PSDrive -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'foo', it should return 2 Item" {
            $Results = Invoke-Handler $Completion_PSDriveName -wordToComplete "foo"

            Assert-MockCalled Get-PSDrive -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }

        It "given a Name '*bar', it should return 2 Item" {
            $Results = Invoke-Handler $Completion_PSDriveName -wordToComplete "*bar"

            Assert-MockCalled Get-PSDrive -Exactly 1 -Scope It
            $Results.Count | Should -Be 2
        }
    }
}