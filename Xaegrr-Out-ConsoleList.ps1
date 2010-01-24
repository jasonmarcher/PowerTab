# Out-ConsoleList.ps1
# Creates RawUI Tab result selection list 
# Used by PowerTab 0.9 for PowerShell RTM 
# Replacement of default TabExpansion function 
# /\/\o\/\/ 2007 
# http://www.ThePowerShellGuy.com

[consoleColor]$BorderColor='darkGreen'
[consoleColor]$BackColor='black'
[consoleColor]$TextColor='green'
[consoleColor]$SelectedBackColor='green'
[consoleColor]$SelectedTextColor='black'
[consoleColor]$BorderTextColor='black'
[consoleColor]$FilterColor='white'

Function Out-ConsoleList {

    param($LastWord='')
    $items = @($input)
	$filter = ""
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
			
			#Xaegr: some optimization
			$LineBuffer = $host.ui.rawui.NewBufferCellArray(@([string]::join("",($LineBuffer|%{$_.character}))),$fgc,$bgc)
            #0..($LineBuffer.Length -1) |% {$c = $LineBuffer[0,$_];$c.ForegroundColor = $fgc;$c.BackgroundColor = $bgc;$LineBuffer[0,$_] = $c}
            $host.ui.rawui.SetBufferContents($Pos,$LineBuffer)
    }
    Function Move-List ($x,$y,$Width,$Height,$Offset){
        $pos  = $host.UI.RawUI.windowposition
        $rect = "system.management.automation.host.rectangle"
        $posOld = $pos
        $pos.Y += $Y
        $pos.X += $X
		#Xaegr: optimization
        $re = new-object $rect $pos.x,$pos.y,($pos.x + $width),($pos.y + $height -1)
		#$re2 = new-object $rect $pos.x,$pos.y,($pos.x + $width),($pos.y + $height -1)
        $pos.Y += $OffSet
        $Host.UI.RawUI.ScrollBufferContents($re,$pos,$re,( new-object System.Management.Automation.Host.BufferCell))
        #$Host.UI.RawUI.ScrollBufferContents($re,$pos,$re2,( new-object System.Management.Automation.Host.BufferCell))
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
            
    0,1 |% {ColorLine $X ($Y + $_) $ListWidth $BorderColor}

    $items[0..($MaxItems -1)] |% {$i = 1}{
        ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
        ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
        WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
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
  SelectLine ($X + 2) ($Y + $Index) ($max) $SelectedTextColor $SelectedBackColor
  #WriteLine ($X + 2) ($Y + $Last + 1 ) " [ $($SelectedItem ) of $($items.count) ]   " $TextColor $backColor
  $Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  $Continue = $true
  while ( $key.VirtualKeyCode -ne 27 -and $Continue -eq $true) {
    Switch ($key.VirtualKeyCode){
        38 { #Up
			#Move-Selection 1
			if ($SelectedItem -ne 1) #Xaegr: remove blinking effect when top reached
			{
	            SelectLine ($X + 2) ($Y + $Index) ($max) $TextColor $BackColor
	            If ($SelectedItem -gt 1 ) {$SelectedItem--;$index--
	                If ($Index -lt 1) {$Index = 1;$Offset--
	                  Move-List ($X +2) ($y+1) ($max) $last 1
	                  WriteLine ($X + 2) ($Y + 1) ($items[$SelectedItem - 1] ) $TextColor $BackColor
	                }
	            }
	            If ($Index -lt 1) {$Index = 1;$Offset--}
	            SelectLine ($X + 2) ($Y + $Index) ($max) $SelectedTextColor $SelectedBackColor
			}
			break
        }
        40 { #Down
			#Move-Selection -1
			if ($SelectedItem -ne $items.Length) #Xaegr: remove blinking effect when bottom reached
			{
	            SelectLine ($X + 2) ($Y + $Index) ($max ) $TextColor $BackColor
				#Xaegr: removed not neccesary if
	            $SelectedItem++;$Index++
	            If ($Index -gt $last) {$Index = $last;$Offset++
	                Move-List ($x+2) ($y+1) ($max) ($Last) (-1)
	                WriteLine ($X + 2) ($Y + $Last) ($items[$SelectedItem - 1] ) $TextColor $BackColor
	            }
	            SelectLine ($X + 2) ($Y + $Index) ($max ) $SelectedTextColor $SelectedBackColor   
			}
			break
        }
		
		33 { #PageUp
			#Move-Selection $MaxItems
			if($selectedItem -gt 1)
			{
			    if($index -eq 1)
				{
					if($selectedItem-$MaxItems -gt 0)
					{
						$SelectedItem-=$MaxItems
				        $Offset-=$MaxItems
					}
					else
					{
						$selectedItem=1
						$Offset=0
						$index=1
					}
					$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
					    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
					    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
					    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
					    $i++
					}
				}
				else
				{
					SelectLine ($X + 2) ($Y + $index) ($max) $TextColor $BackColor
					$index=1
					$selectedItem=1+$offset
				}
				SelectLine ($X + 2) ($Y +1) ($max) $SelectedTextColor $SelectedBackColor
			}
			break
        }
        34 { #PageDown
			if($selectedItem -lt $items.length)
			{
			    if($index -eq $maxItems)
				{
					if($selectedItem+$MaxItems -lt $items.length)
					{
						$SelectedItem+=$MaxItems
				        $Offset+=$MaxItems
					}
					else
					{
						$selectedItem=$items.length
						$Offset=$items.length - $maxItems
						$index=$SelectedItem-$offset
					}
					$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
					    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
					    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
					    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
					    $i++
					}
				}
				else
				{
					SelectLine ($X + 2) ($Y + $index) ($max) $TextColor $BackColor
					$index=$listHeight-2
					$selectedItem=$index+$offset
				}
				SelectLine ($X + 2) ($Y +$index) ($max) $SelectedTextColor $SelectedBackColor
			}
			break
        }

		190 { #Dot
            $Items[$SelectedItem - 1] + '.'
            $Continue = $False
			break
        }
		# Xaegr: added space
        {13,32 -contains $_} { #Enter or space
            $Items[$SelectedItem - 1]
            $Continue = $False
			break
        }
##		{36} { #Home
##			$selectedItem=1
##			$Offset=0
##			$index=1
##			$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
##			    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
##			    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
##			    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
##			    $i++
##			}
##			SelectLine ($X + 2) ($Y +1) ($max) $SelectedTextColor $SelectedBackColor
##		}
##		{35} { #End
##			$selectedItem=$items.length
##			$Offset=$items.length - $maxItems
##			$index=$SelectedItem-$offset
##			$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
##			    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
##			    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
##			    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
##			    $i++
##			}
##			SelectLine ($X + 2) ($Y + $index) ($max) $SelectedTextColor $SelectedBackColor
##		}
		# Xaegr: remove last char of filter
		8 { #Backspace
            if ($filter)
			{
				$filter=$filter.substring(0,$filter.length-1)
			}
			else
			{
				$Continue = $False
			}
			break
        }
		#Xaegr: append char to filter
		{$_ -ge 47 -and $_ -le 126}  { #Char or digit or symbol
			$filter+=$key.character
			
			#### Search
			$toSelect=0
			for($i=1; $i -le $items.length;$i++){
				if($items[$i-1].length -ge "$lastWord$filter".length)
				{
					if($items[$i-1].tolower().startswith("$lastWord$filter".tolower()))
					{
						$toSelect=$i; break
					}
				}
			}
			
			#Select
			if($selectedItem,0 -notcontains $toSelect)
			{
				if($toSelect -gt $offset -and $toSelect -le $offset + $listHeight - 2)
				{
					SelectLine ($X + 2) ($Y + $index) ($max) $TextColor $BackColor
					$selectedItem=$toSelect
					$index=$SelectedItem-$offset
				}
				elseif($toSelect -gt $offset + $listHeight - 2)
				{
					$selectedItem = $toSelect
					$index = $maxItems
					$offset = $toSelect - $maxItems
					$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
					    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
					    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
					    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
					    $i++
					}
				}
				else
				{
					$selectedItem = $toSelect
					$index = 1
					$offset = $toSelect - 1
					$items[$Offset..($Offset + $MaxItems -1)] |% {$i = 1}{
					    ColorLine $X ($Y + $i + 1) ( $ListWidth ) $BorderColor
					    ColorLine ($X + 1) ($Y + $i) ( $ListWidth - 2 ) $BackColor
					    WriteLine ($X + 2) ($Y + $i) $_ $TextColor $BackColor
					    $i++
					}
				}
				
				SelectLine ($X + 2) ($Y +$index) ($max) $SelectedTextColor $SelectedBackColor
			}			
			break
		}
    }
	WriteLine ($X + 2) ($Y + $last + 1) $lastWord $BorderTextColor $BorderColor
	WriteLine ($X + 2 + $lastWord.length) ($Y + $last + 1) "$filter " $FilterColor $BorderColor
	
	#WriteLine ($x) ($y+$CursorOffset) "$filter " $Host.UI.RawUI.ForegroundColor $Host.UI.RawUI.BackgroundColor
	$host.ui.rawui.windowtitle="toSelect=$toSelect, index=$index, offset=$offset, selecteditem=$selecteditem, listHeight=$listHeight, KeyCode="+$key.VirtualKeyCode
	WriteLine ($X + 2) $Y " [ $($SelectedItem ) of $($items.count) ]   " $BorderTextColor $BorderColor
    #WriteLine ($X + 2) ($Y + $last + 1) " [ $($SelectedItem ) of $($items.count) ]   " $BorderTextColor $BorderColor
    If ($Continue) {$Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')}
  }
  $host.ui.rawui.SetBufferContents($ListPosition,$buffer)
  if ($key.VirtualKeyCode -eq 27) {Return $LastWord}
}
