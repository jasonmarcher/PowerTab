# Out-ConsoleList.ps1
# Creates RawUI Tab result selection list 
# Used by PowerTab 0.9 for PowerShell RTM 
# Replacement of default TabExpansion function 
# /\/\o\/\/ 2007 
# http://www.ThePowerShellGuy.com

Function Out-ConsoleList {

    param($LastWord='')
    $items = @($input)
    
    # Not Show List just forward input in case less then 2 options
    if ($items.Length -lt 2){Return $items}
    
   
    # Load Helper functions
    
    Function ColorLine ($x,$y,$l,[system.consolecolor]$bgc) {
    $pos = $host.ui.RawUI.WindowPosition
    $pos.x += $x
    $pos.y += $y
    $row = $host.ui.rawui.NewBufferCellArray((' ' * $l),$bgc,$bgc) 
    $host.ui.rawui.SetBufferContents($pos,$row) 
    } 
    
    Function WriteLine ($x,$y,[string]$Text,[system.consolecolor]$fgc,[system.consolecolor]$bgc) {
    $pos = $host.ui.RawUI.WindowPosition
    $pos.x += $x
    $pos.y += $y
    $row = $host.ui.rawui.NewBufferCellArray($text,$fgc,$bgc) 
    $host.ui.rawui.SetBufferContents($pos,$row) 
    } 
    
    Function SelectLine ($x,$y,$w,[system.consolecolor]$fgc,[system.consolecolor]$bgc) {
            $pos = $host.ui.RawUI.WindowPosition
            $pos.x += $x
            $pos.y += $y
            $rect = "system.management.automation.host.rectangle" 
            $LineRect = new-object $rect $pos.x,$pos.y,($pos.x + $w),($pos.y) 
            $LineBuffer = $host.ui.rawui.getbuffercontents($LineRect) 
            0..($LineBuffer.Length -1) |% {$c = $LineBuffer[0,$_];$c.ForegroundColor = $fgc;$c.BackgroundColor = $bgc;$LineBuffer[0,$_] = $c}
            $host.ui.rawui.SetBufferContents($Pos,$LineBuffer)
    }
    Function Move-List ($x,$y,$Width,$Height,$Offset){
        $pos  = $host.UI.RawUI.windowposition
        $rect = "system.management.automation.host.rectangle"
        $posOld = $pos
        $pos.Y += $Y
        $pos.X += $X
        $re = new-object $rect $pos.x,$pos.y,($pos.x + $width),($pos.y + $height -1)
        $re2 = new-object $rect $pos.x,$pos.y,($pos.x + $width),($pos.y + $Height -1)
        $pos.Y += $OffSet
        $Host.UI.RawUI.ScrollBufferContents($re,$pos,$re2,( new-object System.Management.Automation.Host.BufferCell))
    }
    
    # Main 
    
    $WindowPosition  = $host.UI.rawui.windowposition
    $WindowSize = $Host.UI.RawUI.WindowSize
    $Cursor = $host.UI.RawUI.CursorPosition
    $Center = [math]::Truncate($WindowSize.Height / 2)
    $CursorOffset = $Cursor.Y - $WindowPosition.Y
    $CursorOffsetBottom = $WindowSize.Height - $CursorOffset
        
    # Calculate Placement ConsoleList
    
    $ListHeight = $items.Length + 2 
    $ListPosition = $WindowPosition
    
    If ( $CursorOffset -gt $center -and $ListHeight -gt $CursorOffsetBottom  ) {$Placement = 'Above'} else {$Placement =  'Below'}

    Switch ($placement) {
        'Above' {
            $MaxListHeight =  $CursorOffset
            if ($MaxListHeight -lt $ListHeight) {$listHeight = $MaxListHeight}
            $Y = $CursorOffset - $listHeight
        }
        'Below' {
            $MaxListHeight = ($WindowSize.Height - $CursorOffset) -2 
            if ($MaxListHeight -lt $ListHeight) {$listHeight = $MaxListHeight}
            $Y = $CursorOffSet + 1
        }
    }
    $MaxItems = $MaxListHeight -2
    
    $size = $host.UI.RawUI.buffersize 
    $rect = "system.management.automation.host.rectangle" 

    # Size and Place ConsoleList
    
    $max = $items |% {([string]$_).length} | Measure-Object -Maximum |% {$_.maximum}
    $ListWidth = $max + 4
    if ($ListWidth -ge $Size.width) {$ListWidth = $size.width -1 }
    if ($ListWidth -lt 12) {$ListWidth = 12 }
    $Max = $ListWidth -4    
    
    # Decide about vertical placement
    
    if ( ($Cursor.X + $max) -lt $WindowSize.Width ) {
            $X = $Cursor.X
    } else {        
        if (($Cursor.X - $max ) -gt 0) {
            $X = ($Cursor.X - $max )
        } else {
            $X = $windowSize.Width - $max
        }
    }
     
     $ListPosition.X += $X 
     $ListPosition.Y += $y
    $re = new-object $rect ($ListPosition.X),($ListPosition.Y),($ListPosition.X + $ListWidth),($ListPosition.Y + $ListHeight) 
    $buffer = $host.UI.RawUI.getbuffercontents($re) 
    
    # paint ConsoleList    
            
    0,1 |% {ColorLine $X ($Y + $_) $ListWidth 'darkBlue'}

    $items[0..($MaxItems -1)] |% {$i = 1}{
        ColorLine $X ($Y + $i + 1) ( $ListWidth ) 'darkBlue'
        ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) 'DarkGray'
        WriteLine ($X + 2) ($Y + $i) $_ 'Yellow' 'DarkGray'
        $i++
    }
if ($items.Length -lt $maxItems) {
    $last = $items.Length
  } Else {
    $Last = $MaxItems 
  }

  $SelectedItem = 1
  $Index = $SelectedItem
  $Offset = 0
  SelectLine ($X + 2) ($Y + $Index) ($max) 'Red' 'DarkMagenta'
  WriteLine ($X + 2) ($Y + $Last + 1 ) " [ $($SelectedItem ) of $($items.count) ]   " 'Yellow' 'darkBlue'
  $Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  $Continue = $true
  while ( $key.VirtualKeyCode -ne 27 -and $Continue -eq $true) {
    Switch ($key.VirtualKeyCode){
        38 {
            SelectLine ($X + 2) ($Y + $Index) ($max) 'Yellow' 'DarkGray'
            If ($SelectedItem -gt 1 ) {$SelectedItem--;$index--
                If ($Index -lt 1) {$Index = 1;$Offset++
                  Move-List ($X +2) ($y+1) ($max) $last 1
                  WriteLine ($X + 2) ($Y + 1) ($items[$SelectedItem - 1] ) 'Yellow' 'DarkGray'
                }
            }
            If ($Index -lt 1) {$Index = 1;$Offset--}
            SelectLine ($X + 2) ($Y + $Index) ($max) 'Red' 'DarkMagenta'
        }
        40 {
            SelectLine ($X + 2) ($Y + $Index) ($max ) 'Yellow' 'DarkGray'
            If ($SelectedItem -lt $items.Length ) {$SelectedItem++;$Index++}
            If ($Index -gt $last) {$Index = $last;$Offset++
                Move-List ($x+2) ($y+1) ($max) ($Last) (-1)
                WriteLine ($X + 2) ($Y + $Last) ($items[$SelectedItem - 1] ) 'Yellow' 'DarkGray'
            }
            SelectLine ($X + 2) ($Y + $Index) ($max ) 'Red' 'DarkMagenta'   
        }
        13 {
            $Items[$SelectedItem - 1]
            $Continue = $False
        }
    }
    WriteLine ($X + 2) ($Y + $last + 1) " [ $($SelectedItem ) of $($items.count) ]   " 'Yellow' 'darkBlue'
    If ($Continue) {$Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')}
  }
  $host.ui.rawui.SetBufferContents($ListPosition,$buffer)
  if ($key.VirtualKeyCode -eq 27) {Return $LastWord}
}
