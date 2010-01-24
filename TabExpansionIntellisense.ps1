# Invoke-Intellisense.ps1 
# Author: Aaron Lerch
# http://www.aaronlerch.com/blog

    # INSERT THE PATH TO THE Lerch.PowershellIntellisense.dll FILE IN THE FOLLOWING LINE
    [void][System.Reflection.Assembly]::LoadFile("c:\powerShell\Lerch.PowershellIntellisense.dll") | out-null
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null
  

function Invoke-Intellisense {
    param([string] $existingText = "")

begin
{

    $validItemCount = 0
    $firstValidItem = $null
    $intellisense = new-object Lerch.PowershellIntellisense.Intellisense
    $fontSize = [Lerch.PowershellIntellisense.Win32]::GetCurrentFontSize()
    $consoleHandle = [Lerch.PowershellIntellisense.Win32]::GetConsoleWindow()
    $windowLoc = [Lerch.PowershellIntellisense.Win32]::GetWindowLocation($consoleHandle)

    
    $intellisense.SetPositionForConsole($windowLoc, $host.UI.RawUI.CursorPosition.X+1, $host.UI.RawUI.CursorPosition.Y, $fontSize)
    $intellisense.SetPrefix($existingText)

}

process
{

    if (($_ -ne $null) -and ($_ -ne ""))
    {
        [void]$intellisense.Add($_)
        $validItemCount += 1
        if ($firstValidItem -eq $null)
        {
            $firstValidItem = $_
        }
    }
}

end
{

    if ($validItemCount -ge 2)
    {
        if ($intellisense.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
        {
            if ($intellisense.SelectedValue -ne "")
            {
                return $intellisense.SelectedValue
            }
        }
    }
    elseif ($firstValidItem -ne $null)
    {
        return $firstValidItem
    }

}
    
}