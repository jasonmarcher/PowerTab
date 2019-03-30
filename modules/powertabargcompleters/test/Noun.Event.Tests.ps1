. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Event.ps1"

Describe -Tag "Unit" "Unit-Noun.Event" {
    Context "EventName" {
        It "given a [System.Diagnostics.Process], it should return 4 Items" {
            $Results = Invoke-Handler $Completion_EventEventName -fakeBoundParameter @{InputObject = 'New-Object System.Diagnostics.Process'}

            $Results.Count | Should -Be 4
        }

        It "given a [System.Diagnostics.Process] and Name 'e', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_EventEventName -wordToComplete "e" -fakeBoundParameter @{InputObject = 'New-Object System.Diagnostics.Process'}

            $Results.Count | Should -Be 2
        }
    }
}