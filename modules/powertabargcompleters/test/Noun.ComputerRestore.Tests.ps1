. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.ComputerRestore.ps1"

$MockObjects = @{Name = "foo"; Root = "d:\"}, @{Name = "bar"; Root = "e:\"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.ComputerRestore" {
    Context "ComputerRestoreDrive" {
        Mock Get-PSDrive {
            param(
                [Parameter(Position = 0)]
                $Name
                ,
                $PSProvider
            )
    
            if ($Name) {
                $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
            }
    
            $MockObjects
        }

        It "given No Arguments, it should return All Items" {
            $Results = Invoke-Handler $Completion_ComputerRestoreDrive

            Assert-MockCalled Get-PSDrive -Exactly 1 -ParameterFilter {$PSProvider -eq "FileSystem"} -Scope It
            $Results.Count | Should -Be $MockObjects.Count
        }

        It "given a Name 'f', it should return 1 Item" {
            $Results = Invoke-Handler $Completion_ComputerRestoreDrive -wordToComplete "f"

            Assert-MockCalled Get-PSDrive -Exactly 1 -ParameterFilter {$PSProvider -eq "FileSystem"} -Scope It
            $Results.Count | Should -Be 1
        }
    }
}