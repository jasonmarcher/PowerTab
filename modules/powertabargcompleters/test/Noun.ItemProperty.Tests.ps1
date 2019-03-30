. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.ItemProperty.ps1"

Describe -Tag "Unit" "Unit-Noun.ItemProperty" {
    Context "ItemPropertyPropertyType" {
        It "given No Arguments, it should return 7 Items" {
            $Results = Invoke-Handler $Completion_ItemPropertyPropertyType

            $Results.Count | Should -Be 7
        }

        It "given a Type '*word', it should return 2 Items" {
            $Results = Invoke-Handler $Completion_ItemPropertyPropertyType -wordToComplete "*word"

            $Results.Count | Should -Be 2
        }
    }
}