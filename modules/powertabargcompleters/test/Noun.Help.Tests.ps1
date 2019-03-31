. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Help.ps1"

$MockObjects = @{Name = "about_foo"}, @{Name = "about_bar"}, @{Name = "Get-Foo"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Help" {
    Mock Get-Help {
        param(
            $Name
        )

        if ($Name) {
            $MockObjects = $MockObjects | Where-Object {$_.Name -like "$Name*"}
        }

        $MockObjects
    }

    Context "HelpName" {
        It "given Name 'about_', it should return All About Items" {
            $Results = Invoke-Handler $Completion_HelpName -wordToComplete "about_"

            Assert-MockCalled Get-Help -Exactly 1 -Scope It
            $Results.Count | Should -Be ($MockObjects | Where-Object {$_.Name -like "about_*"}).Count
        }

        It "given a Name 'about_f', it should return 1 Item" {
            $Results = Invoke-Handler $Completion_HelpName -wordToComplete "about_f"

            Assert-MockCalled Get-Help -Exactly 1 -Scope It
            $Results.Count | Should -Be 1
        }
    }
}