. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.History.ps1"

$MockObjects = @{Id = 1; CommandLine = "Get-Foo"}, @{Id = 2; CommandLine = "Get-Bar"},
    @{Id = 3; CommandLine = "Invoke-Foo"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.History" {
    Mock Get-History {
        $MockObjects
    }

    Context "HistoryId" {
        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_HistoryId

            Assert-MockCalled Get-History -Exactly 1 -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }
    }
}