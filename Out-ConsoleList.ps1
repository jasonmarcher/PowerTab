# Out-ConsoleList.ps1
# Creates RawUI Tab result selection list 
# Used by PowerTab 0.95 for PowerShell RTM 
# Replacement of default TabExpansion function 
# /\/\o\/\/ and Xaegr 2007 
# http://www.ThePowerShellGuy.com


Function Out-ConsoleList {

    param($LastWord='')
    &{
      $script:msg = ''
      Set-Variable TabExpansionBorderColor ([consolecolor]($PowerTabConfig.Colors.BorderColor)) -scope 1
      Set-Variable TabExpansionBackColor ([consolecolor]($PowerTabConfig.Colors.BackColor)) -scope 1
      Set-Variable TabExpansionTextColor ([consolecolor]($PowerTabConfig.Colors.TextColor)) -scope 1
      Set-Variable TabExpansionSelectedBackColor ([consolecolor]($PowerTabConfig.Colors.SelectedBackColor)) -scope 1
      Set-Variable TabExpansionSelectedTextColor ([consolecolor]($PowerTabConfig.Colors.SelectedTextColor)) -scope 1
      Set-Variable TabExpansionBorderTextColor ([consolecolor]($PowerTabConfig.Colors.BorderTextColor)) -scope 1
      Set-Variable TabExpansionFilterColor ([consolecolor]($PowerTabConfig.Colors.FilterColor)) -scope 1
      Set-Variable TabExpansionCloseListOnEmptyFilter  ($PowerTabConfig.CloseListOnEmptyFilter) -scope 1
    }
    $allItems = $items = @($input)
 
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
    
    Function WriteLine ($x,$y,[string]$Text ,[system.consolecolor]$fgc,[system.consolecolor]$bgc) {
        $pos = $host.ui.RawUI.WindowPosition
        $pos.x += $x
        $pos.y += $y
        if ($text -eq '') {$text = '-'}
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
        $pos.Y += $OffSet
        $Host.UI.RawUI.ScrollBufferContents($re,$pos,$re,( new-object System.Management.Automation.Host.BufferCell))

    }
	    
    ## Main ##
    
    # Get Positioning data
    
    $WindowPosition  = $host.UI.rawui.windowposition
    $WindowSize = $Host.UI.RawUI.WindowSize
    $Cursor = $host.UI.RawUI.CursorPosition
    $Center = [math]::Truncate($WindowSize.Height / 2)
    $CursorOffset = $Cursor.Y - $WindowPosition.Y
    $CursorOffsetBottom = $WindowSize.Height - $CursorOffset
    $size = $host.UI.RawUI.buffersize 
    $rect = "system.management.automation.host.rectangle" 
    
    $ListPosition = $WindowPosition
        
    # Calculate Placement ConsoleList
    function Calculate-ListVerticalPosition {
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
    }
    $ListHeight = $items.Length + 2
    If ( $CursorOffset -gt $center -and $ListHeight -gt $CursorOffsetBottom  ) {$Placement = 'Above'} else {$Placement =  'Below'}
    . Calculate-ListVerticalPosition
    

    # Size and Place ConsoleList
    
    $max = $items |% {([string]$_).length} | Measure-Object -Maximum |% {$_.maximum}
    $ListWidth = $max + 4
    if ($ListWidth -ge $Size.width) {$ListWidth = $size.width -1 }
    if ($ListWidth -lt 18) {$ListWidth = 18 }
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
    $re = new-object $rect ($ListPosition.X),($ListPosition.Y),($ListPosition.X + $ListWidth),($ListPosition.Y + ($ListHeight - 1)) 
    $buffer = $host.UI.RawUI.getbuffercontents($re) 
    
    # paint ConsoleList    
   
    Function Paint-List ($start,$end,$noBorder = $false){        

        ####Xaegr:0.9.2
        $itemBuff = $items[$start..($end)]
        
        If (-not $noBorder ) {
            $pos = $WindowPosition
            $pos.x += $X
            $pos.y += ($Y)
            $buffLines = @(' ' * $ListWidth)*($itemBuff.count + 2)
            $row = $host.ui.rawui.NewBufferCellArray($buffLines,"green",$TabExpansionBorderColor) 
            $host.ui.rawui.SetBufferContents($pos,$row) 
        }
        $pos = $WindowPosition
        $pos.x += $X + 1
        $pos.y += ($Y+1)
        $buffLines = @(' ' * ($ListWidth - 2))*($itemBuff.count)
        $row = $host.ui.rawui.NewBufferCellArray($buffLines,"green",$TabExpansionBackColor) 
        $host.ui.rawui.SetBufferContents($pos,$row) 

        $pos = $WindowPosition
        $pos.x += $X + 2
        $pos.y += ($Y+1)
        $buffLines = $items[$start..($end)]
        $row = $host.ui.rawui.NewBufferCellArray($buffLines,$TabExpansionTextColor,$TabExpansionBackColor) 
        $host.ui.rawui.SetBufferContents($pos,$row) 
        if ($items.Length -lt $maxItems) {
            $last = $items.Length
        } Else {
            $Last = $MaxItems 
        }
        $SelectedItem = 1
        $Index = $SelectedItem
        $Offset = 0
        SelectLine ($X + 2) ($Y + $Index) ($max) $TabExpansionSelectedTextColor $TabExpansionSelectedBackColor
    }

    . Paint-List 0 ( $MaxItems -1 )
    
    WriteLine ($X + 2) ($Y) $lastWord $TabExpansionBorderTextColor $TabExpansionBorderColor
    WriteLine ($X + 2 + $lastWord.length) ($Y) "$filter " $TabExpansionFilterColor $TabExpansionBorderColor
    WriteLine ($X + 2) ($Y + $last + 1) " [ $($SelectedItem ) of $($items.count) ] $($script:msg) " $TabExpansionBorderTextColor $TabExpansionBorderColor
    # Ask for key and start loop

    $Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $Continue = $true
  
    # Process key's
    $filter = ''
    while ( $key.VirtualKeyCode -ne 27 -and $Continue -eq $true) {
    
        $Shift = $key.ControlKeyState.tostring()

        Switch ($key.VirtualKeyCode){
            {(38 -contains $_) -or ((9 -contains $_) -and ($shift -match 'ShiftPressed'))} { #Up
                #Move-Selection 1
                if ($SelectedItem -ne 1) #Xaegr: remove blinking effect when top reached
                {
                    SelectLine ($X + 2) ($Y + $Index) ($max) $TabExpansionTextColor $TabExpansionBackColor
                    If ($SelectedItem -gt 1 ) {$SelectedItem--;$index--
                        If ($Index -lt 1) {
                            $Index = 1;$Offset--
                            Move-List ($X +2) ($y+1) ($max) $last 1
                            WriteLine ($X + 2) ($Y + 1) ($items[$SelectedItem - 1] ) $TabExpansionTextColor $TabExpansionBackColor
                        }
                    }
                    If ($Index -lt 1) {$Index = 1;$Offset--}
                    SelectLine ($X + 2) ($Y + $Index) ($max) $TabExpansionSelectedTextColor $TabExpansionSelectedBackColor
                }
                break
            }
            {(40,9 -contains $_) -and -not ($shift -match 'ShiftPressed')}  { #Down
                #Move-Selection -1
                if ($SelectedItem -ne $items.Length) #Xaegr: remove blinking effect when bottom reached
                {
                    SelectLine ($X + 2) ($Y + $Index) ($max ) $TabExpansionTextColor $TabExpansionBackColor
                    #Xaegr: removed not neccesary if
                    $SelectedItem++;$Index++
                    If ($Index -gt $last) {$Index = $last;$Offset++
                        Move-List ($x+2) ($y+1) ($max) ($Last) (-1)
                        WriteLine ($X + 2) ($Y + $Last) ($items[$SelectedItem - 1] ) $TabExpansionTextColor $TabExpansionBackColor
                    }
                    SelectLine ($X + 2) ($Y + $Index) ($max ) $TabExpansionSelectedTextColor $TabExpansionSelectedBackColor   
                }
                break
            }
            
            33 { #PageUp
            
                if($selectedItem -gt 1)
                    {
                        if($index -eq 1)
                            {
                                if($selectedItem - $listHeight + 2 -gt 0)
                                    {
                                        $SelectedItem-=$listHeight - 2
                                        $Offset-=$listHeight - 2
                                    }
                                else
                                {
                                    $selectedItem=1
                                    $Offset=0
                                    $index=1
                                }
                                paint-list $offset ($offset + $listHeight - 3) $true
                            }
                            else
                                {
                                    SelectLine ($X + 2) ($Y + $index) ($max) $TabExpansionTextColor $TabExpansionBackColor
                                    $index=1
                                    $selectedItem=1+$offset
                                }
                            SelectLine ($X + 2) ($Y +1) ($max) $TabExpansionSelectedTextColor $TabExpansionSelectedBackColor
                    }
                break
            }
            34 { #PageDown
                if($selectedItem -lt $items.length)
                    {
                        if($index -eq $listHeight-2)
                            {
                                if($selectedItem + $listHeight-2 -lt $items.length)
                                    {
                                        $SelectedItem+=$listHeight-2
                                        $Offset+=$listHeight-2
                                    }
                                else
                                    {
                                        $selectedItem=$items.length
                                        $Offset=$selectedItem - $listHeight + 2
                                        $index=$SelectedItem-$offset
                                    }
                    
                                paint-list $offset ($offset + $listheight-3) $true 
                                SelectLine ($X + 2) ($y+1) ($max) $TabExpansionTextColor $TabExpansionBackColor
                            }
                        else
                            {
                                SelectLine ($X + 2) ($Y + $index) ($max) $TabExpansionTextColor $TabExpansionBackColor
                                $index=$listHeight-2
                                $selectedItem=$index+$offset
                            }
                            
                        SelectLine ($X + 2) ($Y +$index) ($max) $TabExpansionSelectedTextColor $TabExpansionSelectedBackColor
                    }
                break
            }
            
            
            
            190 { #Dot
                $Items[$SelectedItem - 1]
                $Continue = $False
                #TabExpansion [regex]::Escape($Items[$SelectedItem - 1] + '.') [regex]::Escape($Items[$SelectedItem - 1] + '.')
                break
            }
            # Xaegr: added space
            32 { #Space
                $Items[$SelectedItem - 1] + ' '
                $Continue = $False
                break
            }
            13 { #Enter
                $Items[$SelectedItem - 1]
                $Continue = $False
                break
            }
            # Xaegr: remove last char of filter
            8 { #Backspace
                if ($filter)
                {
                    $filter=$filter.substring(0,$filter.length-1)
                    
                    #Xaegr:0.9.1:Added for filter at cursor position
                    $host.ui.write($key.character)
                    WriteLine ($host.UI.RawUI.CursorPosition.x) ($host.UI.RawUI.CursorPosition.y-$host.UI.RawUI.WindowPosition.y) " " $TabExpansionFilterColor $Host.UI.RawUI.BackgroundColor
                    #Xaegr:0.9.1:EndOfChanges
                    
                    $items = $allItems -match ([regex]::Escape("$lastword$Filter") +'.*')
                    $ListHeight = $items.Length + 2
                    $host.ui.rawui.SetBufferContents($ListPosition,$buffer)
                    . Calculate-ListVerticalPosition
                    . Paint-List 0 ( $MaxItems -1 )
                }
                else
                {
                    #Xaegr:0.9.1:Changed for option to close list or beep ($TabExpansionCloseListOnEmptyFilter)
                    if ($TabExpansionCloseListOnEmptyFilter)
                    {
                        $key.VirtualKeyCode = 27
                        $Continue = $False
                    }
                    else
                    {
                        Write-Host -no "`a"
                    }
                    #Xaegr:0.9.1:EndOfChanges
                }
                break
            }
            #Xaegr: append char to filter
            {$_ -ge 35 -and $_ -le 126}  { #Char or digit or symbol
                $filter+=$key.character
                $items = $allItems -match ([regex]::Escape("$lastword$Filter") +'.*')
                if ($items.Length -lt 1) {
                    Write-Host -no "`a"
                    $filter=$filter.substring(0,$filter.length-1)
                    $items = $allItems -match ([regex]::Escape("$lastword$Filter") +'.*')
                } Else {
                
                    #Xaegr:0.9.1:Added for filter at cursor position
                    $host.ui.write($TabExpansionFilterColor,$Host.UI.RawUI.BackgroundColor,$key.character)
                    #Xaegr:0.9.1:EndOfChanges
                }
                
                $ListHeight = $items.Length + 2
                $host.ui.rawui.SetBufferContents($ListPosition,$buffer)
                . Calculate-ListVerticalPosition
                . Paint-List 0 ( $MaxItems -1 )
                break
            }
        }
    
        WriteLine ($X + 2) ($Y) $lastWord $TabExpansionBorderTextColor $TabExpansionBorderColor
        WriteLine ($X + 2 + $lastWord.length) ($Y) "$filter " $TabExpansionFilterColor $TabExpansionBorderColor
        WriteLine ($X + 2) ($Y + $last + 1) " [ $($SelectedItem ) of $($items.count) ] $($script:msg) " $TabExpansionBorderTextColor $TabExpansionBorderColor
    
        If ($Continue) {$Key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')}
   }

   # put back old buffer information and return $lastword on cancel

   $host.ui.rawui.SetBufferContents($ListPosition,$buffer)
    if ($key.VirtualKeyCode -eq 27) {
		WriteLine ($host.UI.RawUI.CursorPosition.x -1 ) ($host.UI.RawUI.CursorPosition.y-$host.UI.RawUI.WindowPosition.y) " " $TabExpansionFilterColor $Host.UI.RawUI.BackgroundColor
        Return "$LastWord$filter"
    }

}
