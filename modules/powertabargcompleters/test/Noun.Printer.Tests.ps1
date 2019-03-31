. "$TestDirectory/Test-Utility.ps1"

. "$SrcDirectory/completers/Noun.Printer.ps1"

$MockObjects = @{Name = "Foo"}, @{Name = "Bar"}, @{Name = "FooBar"} |
    ForEach-Object {New-Object PSObject -Property $_}

Describe -Tag "Unit" "Unit-Noun.Printer" {
    Context "PrinterName" {
        Mock Get-CimInstance {
            param(
                $ClassName,
                $Filter
            )

            $MockObjects
        }

        It "it should call 'Get-CimInstance' with the correct arguments" {
            $Results = Invoke-Handler $Completion_PrinterName

            $ParameterFilter = {$ClassName -eq "Win32_Printer" -and $Filter -eq "Name LIKE '%'"}
            Assert-MockCalled Get-CimInstance -Exactly 1 -ParameterFilter $ParameterFilter -Scope It
        }
    }
}