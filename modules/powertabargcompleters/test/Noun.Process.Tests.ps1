. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Process.ps1"

$MockObjects = @{Id = "1"; Name = "Process 1"}, @{Id = "2"; Name = "Process 2"},
    @{Id = "3"; Name = "Process 3"}, @{Id = "10"; Name = "Foo Ten"},
    @{Id = "1000"; Name = "Bar Thousand"},@{Id = "10000"; Name = "Baz Ten-Thousand"},
    @{Id = "20000"; Name = "Baz Twenty-Thousand"} | ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Process" {
    Mock Get-Process {
        param(
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "ProcessId" {
        $TextPattern = "{0,-4} <# {1} #>"

        It "given No Arguments, it should return 7 Items" {
            $Results = Invoke-Handler $Completion_ProcessId

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 7
        }

        It "given an ID '1', it should return 4 Items" {
            $Results = Invoke-Handler $Completion_ProcessId -wordToComplete "1"

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 4
        }

        It "given a Name 'Proc', it should return 3 Items" {
            $Results = Invoke-Handler $Completion_ProcessId -wordToComplete "Proc"

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 3
        }

        It "given No Arguments, the display text for each result should be propertly formatted" {
            $Results = Invoke-Handler $Completion_ProcessId

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            for ($i = 0; $i -lt $Results.Count; $i++) {
                $Results[$i].ListItemText | Should -Be ($TextPattern -f $MockObjects[$i].Id, $MockObjects[$i].Name)
            }
        }
    }

    Context "ProcessName" {
        It "given No Arguments, it should return 7 Items" {
            $Results = Invoke-Handler $Completion_ProcessName

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 7
        }

        It "given a Name 'Proc', it should return 3 Items" {
            $Results = Invoke-Handler $Completion_ProcessName -wordToComplete "Proc"

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 3
        }

        It "given a Name '*Thousand', it should return 3 Items" {
            $Results = Invoke-Handler $Completion_ProcessName -wordToComplete "Proc"

            Assert-MockCalled Get-Process -Exactly 1 -Scope It
            $Results.Count | Should -Be 3
        }
    }
}