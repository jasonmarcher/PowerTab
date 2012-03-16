# ConsoleLib.ps1
#
# 


Function Out-ConsoleList {
    #[CmdletBinding()]
    param(
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [String]
        $LastWord = ''
        ,
        [Parameter(Position = 2)]
        [ValidateNotNull()]
        [String]
        $ReturnWord = ''  ## Text to return with filter if list closes without a selected item
        ,
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object[]]
        $InputObject = @()
        ,
        [Switch]
        $ForceList
    )

    begin {
        [Object[]]$Content = @()
        $NestedPowerTab = $true
    }

    process {
        $Content += $InputObject
    }

    end {
        if (-not $PSBoundParameters.ContainsKey("ReturnWord")) {$ReturnWord = $LastWord}

        ## If contents contains less than minimum options, then forward contents without displaying console list
        if (($Content.Length -lt $PowerTabConfig.MinimumListItems) -and (-not $ForceList)) {
            $Content | Select-Object -ExpandProperty Value
            return
        }

        ## If the shift key is pressed, then output the first result without displaying console list
        if (Get-KeyState 0x10) {
            $Content[0].Value
            return
        }

        ## Create console list
        $Filter = ''
        $ListHandle = New-ConsoleList $Content $PowerTabConfig.Colors.BorderColor $PowerTabConfig.Colors.BorderBackColor `
            $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor

        ## Preview of current filter, shows up where cursor is at
        $PreviewBuffer =  ConvertTo-BufferCellArray "$Filter " $PowerTabConfig.Colors.FilterColor $Host.UI.RawUI.BackgroundColor
        $Preview = New-Buffer $Host.UI.RawUI.CursorPosition $PreviewBuffer

        Function Add-Status {
            ## Title buffer, shows the last word in header of console list
            $TitleBuffer = ConvertTo-BufferCellArray " $LastWord" $PowerTabConfig.Colors.BorderTextColor $PowerTabConfig.Colors.BorderBackColor
            $TitlePosition = $ListHandle.Position
            $TitlePosition.X += 2
            $TitleHandle = New-Buffer $TitlePosition $TitleBuffer

            ## Filter buffer, shows the current filter after the last word in header of console list
            $FilterBuffer = ConvertTo-BufferCellArray "$Filter " $PowerTabConfig.Colors.FilterColor $PowerTabConfig.Colors.BorderBackColor
            $FilterPosition = $ListHandle.Position
            $FilterPosition.X += (3 + $LastWord.Length)
            $FilterHandle = New-Buffer $FilterPosition $FilterBuffer

            ## Status buffer, shows at footer of console list.  Displays selected item index, index range of currently visible items, and total item count.
            $StatusBuffer = ConvertTo-BufferCellArray "[$($ListHandle.SelectedItem + 1)] $($ListHandle.FirstItem + 1)-$($ListHandle.LastItem + 1) [$($Content.Length)]" $PowerTabConfig.Colors.BorderTextColor $PowerTabConfig.Colors.BorderBackColor
            $StatusPosition = $ListHandle.Position
            $StatusPosition.X += 2
            $StatusPosition.Y += ($listHandle.ListConfig.ListHeight - 1)
            $StatusHandle = New-Buffer $StatusPosition $StatusBuffer

        }
        . Add-Status

        ## Select the first item in the list
        $SelectedItem = 0
        Set-Selection 1 ($SelectedItem + 1) ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor

        ## Listen for first key press
        $Key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        ## Process key presses
        $Continue = $true
        while ($Key.VirtualKeyCode -ne 27 -and $Continue -eq $true) {
            if (-not $HasChild) {
                if ($OldFilter -ne $Filter) {
                  $Preview.Clear()
                  $PreviewBuffer = ConvertTo-BufferCellArray "$Filter " $PowerTabConfig.Colors.FilterColor $Host.UI.RawUI.BackgroundColor
                  $Preview = New-Buffer $Preview.Location $PreviewBuffer
                }
                $OldFilter = $Filter
            }
            $ShiftPressed = Get-KeyState 0x10  ## Check for Shift Key
            $HasChild = $false
            switch ($Key.VirtualKeyCode) {
                9 { ## Tab
                    ## In Visual Studio, Tab acts like Enter
                    if ($PowerTabConfig.VisualStudioTabBehavior) {
                        ## Expand with currently selected item
                        $ListHandle.Items[$ListHandle.SelectedItem].Value
                        $Continue = $false
                        break
                    } else {
                        if ($ShiftPressed) {
                            Move-Selection -1  ## Up
                        } else {
                            Move-Selection 1  ## Down
                        }
                        break
                    }
                }
                38 { ## Up Arrow
                    if ($ShiftPressed) {
                        ## Fast scroll selected
                        if ($PowerTabConfig.FastScrollItemCount -gt ($ListHandle.Items.Count - 1)) {
                            $Count = ($ListHandle.Items.Count - 1)
                        } else {
                            $Count = $PowerTabConfig.FastScrollItemCount
                        }
                        Move-Selection (- $Count)
                    } else {
                        Move-Selection -1
                    }
                    break
                }
                40 { ## Down Arrow
                    if ($ShiftPressed) {
                        ## Fast scroll selected
                        if ($PowerTabConfig.FastScrollItemCount -gt ($ListHandle.Items.Count - 1)) {
                            $Count = ($ListHandle.Items.Count - 1)
                        } else {
                            $Count = $PowerTabConfig.FastScrollItemCount
                        }
                        Move-Selection $Count
                    } else {
                        Move-Selection 1
                    }
                    break
                }
                33 { ## Page Up
                    $Count = $ListHandle.Items.Count
                    if ($Count -gt $ListHandle.MaxItems) {
                        $Count = $ListHandle.MaxItems
                    }
                    Move-Selection (-($Count - 1))
                    break
                }
                34 { ## Page Down
                    $Count = $ListHandle.Items.Count
                    if ($Count -gt $ListHandle.MaxItems) {
                        $Count = $ListHandle.MaxItems
                    }
                    Move-Selection ($Count - 1)
                    break
                }
                39 { ## Right Arrow
                    ## Add a new character (the one right after the current filter string) from currently selected item
                    $Char = $ListHandle.Items[$ListHandle.SelectedItem].Text[($LastWord.Length + $Filter.Length + 1)]
                    $Filter += $Char
                    
                    $Old = $Items.Length
                    $Items = $Content -match ([Regex]::Escape("$LastWord$Filter") + '.*')
                    $New = $Items.Length
                    if ($New -lt 1) {
                        ## If new filter results in no items, sound error beep and remove character
                        [System.Console]::Beep()
                        $Filter = $Filter.SubString(0, $Filter.Length - 1)
                    } else {
                        if ($Old -ne $New) {
                            ## Update console list contents
                            $ListHandle.Clear()
                            $ListHandle = New-ConsoleList $Items $PowerTabConfig.Colors.BorderColor $PowerTabConfig.Colors.BorderBackColor `
                                $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
                            ## Update status buffers
                            . Add-Status
                        }
                        ## Select first item of new list
                        $SelectedItem = 0
                        Set-Selection 1 ($SelectedItem + 1) ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor
                        $Host.UI.Write($PowerTabConfig.Colors.FilterColor, $Host.UI.RawUI.BackgroundColor, $Char)
                    }
                    break
                }
                {(8,37 -contains $_)} { # Backspace or Left Arrow
                    if ($Filter) {
                        ## Remove last character from filter
                        $Filter = $Filter.SubString(0, $Filter.Length - 1)
                        $Host.UI.Write([char]8)
                        Write-Line ($Host.UI.RawUI.CursorPosition.X) ($Host.UI.RawUI.CursorPosition.Y - $Host.UI.RawUI.WindowPosition.Y) " " $PowerTabConfig.Colors.FilterColor $Host.UI.RawUI.BackgroundColor

                        $Old = $Items.Length
                        $Items = @($Content | Where-Object {$_.Text -match ([Regex]::Escape("$LastWord$Filter") + '.*')})
                        $New = $Items.Length
                        if ($Old -ne $New) {
                            ## If the item list changed, update the contents of the console list
                            $ListHandle.Clear()
                            $ListHandle = New-ConsoleList $Items $PowerTabConfig.Colors.BorderColor $PowerTabConfig.Colors.BorderBackColor `
                                $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
                            ## Update status buffers
                            . Add-Status
                        }
                        ## Select first item of new list
                        $SelectedItem = 0
                        Set-Selection 1 ($SelectedItem + 1) ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor
                    } else {
                        if ($PowerTabConfig.CloseListOnEmptyFilter) {
                            $Key.VirtualKeyCode = 27
                            $Continue = $false
                        } else {
                            [System.Console]::Beep()
                        }
                    }
                    break
                }
                190 { ## Period
                    if ($PowerTabConfig.DotComplete -and -not $PowerTabFileSystemMode) {
                        if ($PowerTabConfig.AutoExpandOnDot) {
                            ## Expand with currently selected item
                            $Host.UI.Write($Host.UI.RawUI.ForegroundColor, $Host.UI.RawUI.BackgroundColor, ($ListHandle.Items[$ListHandle.SelectedItem].Value.SubString($LastWord.Length + $Filter.Length) + '.'))
                            $ListHandle.Clear()
                            $LinePart = $Line.SubString(0, $Line.Length - $LastWord.Length)

                            ## Remove message handle ([Tab]) because we will be reinvoking tab expansion
                            Remove-TabActivityIndicator

                            ## Recursive tab expansion
                            . TabExpansion ($LinePart + $ListHandle.Items[$ListHandle.SelectedItem].Value + '.') ($ListHandle.Items[$ListHandle.SelectedItem].Value + '.') -ForceList
                            $HasChild = $true
                        } else {
                            $ListHandle.Items[$ListHandle.SelectedItem].Value
                        }
                        $Continue = $false
                        break
                    }
                }
                {'\','/' -contains $Key.Character} { ## Path Separators
                    if ($PowerTabConfig.BackSlashComplete) {
                        if ($PowerTabConfig.AutoExpandOnBackSlash) {
                            ## Expand with currently selected item
                            $Host.UI.Write($Host.UI.RawUI.ForegroundColor, $Host.UI.RawUI.BackgroundColor, ($ListHandle.Items[$ListHandle.SelectedItem].Value.SubString($LastWord.Length + $Filter.Length) + $Key.Character))
                            $ListHandle.Clear()
                            if ($Line.Length -ge $LastWord.Length) {
                                $LinePart = $Line.SubString(0, $Line.Length - $LastWord.Length)
                            }

                            ## Remove message handle ([Tab]) because we will be reinvoking tab expansion
                            Remove-TabActivityIndicator

                            ## Recursive tab expansion
                            . Invoke-TabExpansion ($LinePart + $ListHandle.Items[$ListHandle.SelectedItem].Value + $Key.Character) ($ListHandle.Items[$ListHandle.SelectedItem].Value + $Key.Character) -ForceList
                            $HasChild = $true
                        } else {
                            $ListHandle.Items[$ListHandle.SelectedItem].Value
                        }
                        $Continue = $false
                        break
                    }
                }
                32 { ## Space
                    ## True if "Space" and SpaceComplete is true, or "Ctrl+Space" and SpaceComplete is false
                    if (($PowerTabConfig.SpaceComplete -and -not ($Key.ControlKeyState -match 'CtrlPressed')) -or (-not $PowerTabConfig.SpaceComplete -and ($Key.ControlKeyState -match 'CtrlPressed'))) {
                        ## Expand with currently selected item
                        $Item = $ListHandle.Items[$ListHandle.SelectedItem].Value
                        if ((-not $Item.Contains(' ')) -and ($PowerTabFileSystemMode -ne $true)) {$Item += ' '}
                        $Item
                        $Continue = $false
                        break
                    }
                }
                {($PowerTabConfig.CustomCompletionChars.ToCharArray() -contains $Key.Character) -and $PowerTabConfig.CustomComplete} { ## Extra completions
                    $Item = $ListHandle.Items[$ListHandle.SelectedItem].Value
                    $Item = ($Item + $Key.Character) -replace "\$($Key.Character){2}$",$Key.Character
                    $Item
                    $Continue = $false
                    break
                }
                13 { ## Enter
                    ## Expand with currently selected item
                    $ListHandle.Items[$ListHandle.SelectedItem].Value
                    $Continue = $false
                    break
                }
                {$_ -ge 32 -and $_ -le 190}  { ## Letter or digit or symbol (ASCII)
                    ## Add character to filter
                    $Filter += $Key.Character

                    $Old = $Items.Length
                    $Items = @($Content | Where-Object {$_.Text -match ('^' + [Regex]::Escape("$LastWord$Filter") + '.*')})
                    $New = $Items.Length
                    if ($Items.Length -lt 1) {
                        ## New filter results in no items
                        if ($PowerTabConfig.CloseListOnEmptyFilter) {
                            ## Close console list and return the return word with current filter (includes new character)
                            $ListHandle.Clear()
                            return "$ReturnWord$Filter"
                        } else {
                            ## Sound error beep and remove character
                            [System.Console]::Beep()
                            $Filter = $Filter.SubString(0, $Filter.Length - 1)
                        }
                    } else {
                        if ($Old -ne $New) {
                            ## If the item list changed, update the contents of the console list
                            $ListHandle.Clear()
                            $ListHandle = New-ConsoleList $Items $PowerTabConfig.Colors.BorderColor $PowerTabConfig.Colors.BorderBackColor `
                                $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
                            ## Update status buffer
                            . Add-Status
                            ## Select first item of new list
                            $SelectedItem = 0
                            Set-Selection 1 ($SelectedItem + 1) ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor
                        }

                        $Host.UI.Write($PowerTabConfig.Colors.FilterColor, $Host.UI.RawUI.BackgroundColor, $Key.Character)
                    }
                    break
                }
            }

            ## Listen for next key press
            if ($Continue) {$Key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}
        }

        $ListHandle.Clear()
        if (-not $HasChild) {
            if ($Key.VirtualKeyCode -eq 27) {
        		#Write-Line ($Host.UI.RawUI.CursorPosition.X - 1) ($Host.UI.RawUI.CursorPosition.Y - $Host.UI.RawUI.WindowPosition.Y) " " $PowerTabConfig.Colors.FilterColor $Host.UI.RawUI.BackgroundColor
                ## No items left and request that console list close, so return the return word with current filter
                return "$ReturnWord$Filter"
            }
        }
    }  ## end of "end" block
}


    Function New-Box {
        param(
            [System.Drawing.Size]
            $Size
            ,
            [System.ConsoleColor]
            $ForegroundColor = $Host.UI.RawUI.ForegroundColor
            ,
            [System.ConsoleColor]
            $BackgroundColor = $Host.UI.RawUI.BackgroundColor
        )

        $Box = New-Object System.Management.Automation.PSObject -Property @{
            'HorizontalDouble' = ([char]9552).ToString()
            'VerticalDouble' = ([char]9553).ToString()
            'TopLeftDouble' = ([char]9556).ToString()
            'TopRightDouble' = ([char]9559).ToString()
            'BottomLeftDouble' = ([char]9562).ToString()
            'BottomRightDouble' = ([char]9565).ToString()
            'Horizontal' = ([char]9472).ToString()
            'Vertical' = ([char]9474).ToString()
            'TopLeft' = ([char]9484).ToString()
            'TopRight' = ([char]9488).ToString()
            'BottomLeft' = ([char]9492).ToString()
            'BottomRight' = ([char]9496).ToString()
            'Cross' = ([char]9532).ToString()
            'HorizontalDoubleSingleUp' = ([char]9575).ToString()
            'HorizontalDoubleSingleDown' = ([char]9572).ToString()
            'VerticalDoubleLeftSingle' = ([char]9570).ToString()
            'VerticalDoubleRightSingle' = ([char]9567).ToString()
            'TopLeftDoubleSingle' = ([char]9554).ToString()
            'TopRightDoubleSingle' = ([char]9557).ToString()
            'BottomLeftDoubleSingle' = ([char]9560).ToString()
            'BottomRightDoubleSingle' = ([char]9563).ToString()
            'TopLeftSingleDouble' = ([char]9555).ToString()
            'TopRightSingleDouble' = ([char]9558).ToString()
            'BottomLeftSingleDouble' = ([char]9561).ToString()
            'BottomRightSingleDouble' = ([char]9564).ToString()
        }

        if ($PowerTabConfig.DoubleBorder) {
            ## Double line box
            $LineTop = $Box.TopLeftDouble `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.TopRightDouble
            $LineField = $Box.VerticalDouble `
                + ' ' * ($Size.width - 2) `
                + $Box.VerticalDouble
            $LineBottom = $Box.BottomLeftDouble `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.BottomRightDouble
        } elseif ($false) {
            ## Mixed line box, double horizontal, single vertical
            $LineTop = $Box.TopLeftDoubleSingle `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.TopRightDoubleSingle
            $LineField = $Box.Vertical `
                + ' ' * ($Size.width - 2) `
                + $Box.Vertical
            $LineBottom = $Box.BottomLeftDoubleSingle `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.BottomRightDoubleSingle
        } elseif ($false) {
            ## Mixed line box, single horizontal, double vertical
            $LineTop = $Box.TopLeftDoubleSingle `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.TopRightDoubleSingle
            $LineField = $Box.Vertical `
                + ' ' * ($Size.width - 2) `
                + $Box.Vertical
            $LineBottom = $Box.BottomLeftDoubleSingle `
                + $Box.HorizontalDouble * ($Size.width - 2) `
                + $Box.BottomRightDoubleSingle
        } else {  
            ## Single line box
            $LineTop = $Box.TopLeft `
                + $Box.Horizontal * ($Size.width - 2) `
                + $Box.TopRight
            $LineField = $Box.Vertical `
                + ' ' * ($Size.width - 2) `
                + $Box.Vertical
            $LineBottom = $Box.BottomLeft `
                + $Box.Horizontal * ($Size.width - 2) `
                + $Box.BottomRight
        }
        $Box = & {$LineTop; 1..($Size.Height - 2) | ForEach-Object {$LineField}; $LineBottom}
        $BoxBuffer = $Host.UI.RawUI.NewBufferCellArray($Box, $ForegroundColor, $BackgroundColor)
        ,$BoxBuffer
    }


    Function Get-ContentSize {
        param(
            [Object[]]$Content
        )

        $MaxWidth = @($Content | Select-Object -ExpandProperty Text | Sort-Object Length -Descending)[0].Length
        New-Object System.Drawing.Size $MaxWidth, $Content.Length
    }


    Function New-Position {
        param(
            [Int]$X
            ,
            [Int]$Y
        )

        $Position = $Host.UI.RawUI.WindowPosition
        $Position.X += $X
        $Position.Y += $Y
        $Position
    }


    Function New-Buffer {
        param(
            [System.Management.Automation.Host.Coordinates]
            $Position
            ,
            [System.Management.Automation.Host.BufferCell[,]]
            $Buffer
        )

        $BufferBottom = $BufferTop = $Position
        $BufferBottom.X += ($Buffer.GetUpperBound(1))
        $BufferBottom.Y += ($Buffer.GetUpperBound(0))
        $Rectangle = New-Object System.Management.Automation.Host.Rectangle $BufferTop, $BufferBottom
        $OldBuffer = $Host.UI.RawUI.GetBufferContents($Rectangle)
        $Host.UI.RawUI.SetBufferContents($BufferTop, $Buffer)
        $Handle = New-Object System.Management.Automation.PSObject -Property @{
            'Content' = $Buffer
            'OldContent' = $OldBuffer
            'Location' = $BufferTop
        }
        Add-Member -InputObject $Handle -MemberType ScriptMethod -Name Clear -Value {$Host.UI.RawUI.SetBufferContents($This.Location, $This.OldContent)}
        Add-Member -InputObject $Handle -MemberType ScriptMethod -Name Show -Value {$Host.UI.RawUI.SetBufferContents($This.Location, $This.Content)}
        $Handle
    }


    Function ConvertTo-BufferCellArray {
        param(
            [String[]]
            $Content
            ,
            [System.ConsoleColor]
            $ForegroundColor = $Host.UI.RawUI.ForegroundColor
            ,
            [System.ConsoleColor]
            $BackgroundColor = $Host.UI.RawUI.BackgroundColor
        )

        ,$Host.UI.RawUI.NewBufferCellArray($Content, $ForegroundColor, $BackgroundColor)
    }


    Function Parse-List {
        param(
            [System.Drawing.Size]$Size
        )

        $WindowPosition  = $Host.UI.RawUI.WindowPosition
        $WindowSize = $Host.UI.RawUI.WindowSize
        $Cursor = $Host.UI.RawUI.CursorPosition
        $Center = [Math]::Truncate([Float]$WindowSize.Height / 2)
        $CursorOffset = $Cursor.Y - $WindowPosition.Y
        $CursorOffsetBottom = $WindowSize.Height - $CursorOffset

        # Vertical Placement and size
        $ListHeight = $Size.Height + 2

        if (($CursorOffset -gt $Center) -and ($ListHeight -ge $CursorOffsetBottom)) {$Placement = 'Above'}
        else {$Placement =  'Below'}

        switch ($Placement) {
            'Above' {
                $MaxListHeight = $CursorOffset 
                if ($MaxListHeight -lt $ListHeight) {$ListHeight = $MaxListHeight}
                $Y = $CursorOffset - $ListHeight
            }
            'Below' {
                $MaxListHeight = ($CursorOffsetBottom - 1)  
                if ($MaxListHeight -lt $ListHeight) {$ListHeight = $MaxListHeight}
                $Y = $CursorOffSet + 1
            }
        }
        $MaxItems = $MaxListHeight - 2

        # Horizontal
        $ListWidth = $Size.Width + 4
        if ($ListWidth -gt $WindowSize.Width) {$ListWidth = $Windowsize.Width}
        $Max = $ListWidth 
        if (($Cursor.X + $Max) -lt ($WindowSize.Width - 2)) {
            $X = $Cursor.X
        } else {        
            if (($Cursor.X - $Max) -gt 0) {
                $X = $Cursor.X - $Max
            } else {
                $X = $windowSize.Width - $Max
            }
        }

        # Output
        $ListInfo = New-Object System.Management.Automation.PSObject -Property @{
            'Orientation' = $Placement
            'TopX' = $X
            'TopY' = $Y
            'ListHeight' = $ListHeight
            'ListWidth' = $ListWidth
            'MaxItems' = $MaxItems
        }
        $ListInfo
    }


    Function New-ConsoleList {
        param(
            [Object[]]
            $Content
            ,
            [System.ConsoleColor]
            $BorderForegroundColor
            ,
            [System.ConsoleColor]
            $BorderBackgroundColor
            ,
            [System.ConsoleColor]
            $ContentForegroundColor
            ,
            [System.ConsoleColor]
            $ContentBackgroundColor
        )

        $Size = Get-ContentSize $Content
        $MinWidth = ([String]$Content.Count).Length * 4 + 7
        if ($Size.Width -lt $MinWidth) {$Size.Width = $MinWidth}
        $Content = foreach ($Item in $Content) {
            $Item.DisplayText = "$($Item.Text) ".PadRight($Size.Width + 2)
            $Item
        }
        $ListConfig = Parse-List $Size
        $BoxSize = New-Object System.Drawing.Size $ListConfig.ListWidth, $ListConfig.ListHeight
        $Box = New-Box $BoxSize $BorderForegroundColor $BorderBackgroundColor

        $Position = New-Position $ListConfig.TopX $ListConfig.TopY
        $BoxHandle = New-Buffer $Position $Box

        # Place content 
        $Position.X += 1
        $Position.Y += 1
        $ContentBuffer = ConvertTo-BufferCellArray ($Content[0..($ListConfig.ListHeight - 3)] | Select-Object -ExpandProperty DisplayText) $ContentForegroundColor $ContentBackgroundColor
        $ContentHandle = New-Buffer $Position $ContentBuffer
        $Handle = New-Object System.Management.Automation.PSObject -Property @{
            'Position' = (New-Position $ListConfig.TopX $ListConfig.TopY)
            'ListConfig' = $ListConfig
            'ContentSize' = $Size
            'BoxSize' = $BoxSize
            'Box' = $BoxHandle
            'Content' = $ContentHandle
            'SelectedItem' = 0
            'SelectedLine' = 1
            'Items' = $Content
            'FirstItem' = 0
            'LastItem' = ($Listconfig.ListHeight - 3)
            'MaxItems' = $Listconfig.MaxItems
        }
        Add-Member -InputObject $Handle -MemberType ScriptMethod -Name Clear -Value {$This.Box.Clear()}
        Add-Member -InputObject $Handle -MemberType ScriptMethod -Name Show -Value {$This.Box.Show(); $This.Content.Show()}
        $Handle
    }


    Function Write-Line {
        param(
            [Int]$X
            ,
            [Int]$Y
            ,
            [String]$Text
            ,
            [System.ConsoleColor]
            $ForegroundColor
            ,
            [System.ConsoleColor]
            $BackgroundColor
        )

        $Position = $Host.UI.RawUI.WindowPosition
        $Position.X += $X
        $Position.Y += $Y
        if ($Text -eq '') {$Text = '-'}
        $Buffer = $Host.UI.RawUI.NewBufferCellArray([String[]]$Text, $ForegroundColor, $BackgroundColor)
        $Host.UI.RawUI.SetBufferContents($Position, $Buffer)
    }


    Function Move-List {
        param(
            [Int]$X
            ,
            [Int]$Y
            ,
            [Int]$Width
            ,
            [Int]$Height
            ,
            [Int]$Offset
        )

        $Position = $ListHandle.Position
        $Position.X += $X
        $Position.Y += $Y
        $Rectangle = New-Object System.Management.Automation.Host.Rectangle $Position.X, $Position.Y, ($Position.X + $Width), ($Position.Y + $Height - 1)
        $Position.Y += $OffSet
        $BufferCell = New-Object System.Management.Automation.Host.BufferCell
        $BufferCell.BackgroundColor = $PowerTabConfig.Colors.BackColor
        $Host.UI.RawUI.ScrollBufferContents($Rectangle, $Position, $Rectangle, $BufferCell)
    }


    Function Set-Selection {
        param(
            [Int]$X
            ,
            [Int]$Y
            ,
            [Int]$Width
            ,
            [System.ConsoleColor]
            $ForegroundColor
            ,
            [System.ConsoleColor]
            $BackgroundColor
        )

        $Position = $ListHandle.Position
        $Position.X += $X
        $Position.Y += $Y
        $Rectangle = New-Object System.Management.Automation.Host.Rectangle $Position.X, $Position.Y, ($Position.X + $Width), $Position.Y
        $LineBuffer = $Host.UI.RawUI.GetBufferContents($Rectangle)
        $LineBuffer = $Host.UI.RawUI.NewBufferCellArray(@([String]::Join("", ($LineBuffer | ForEach-Object {$_.Character}))),
            $ForegroundColor, $BackgroundColor)
        $Host.UI.RawUI.SetBufferContents($Position, $LineBuffer)
    }


    Function Move-Selection {
        param(
            [Int]$Count
        )

        $SelectedItem = $ListHandle.SelectedItem
        $Line = $ListHandle.SelectedLine
        if ($Count -eq ([Math]::Abs([Int]$Count))) { ## Down in list
            if ($SelectedItem -eq ($ListHandle.Items.Count - 1)) {return}
            $One = 1
            if ($SelectedItem -eq $ListHandle.LastItem) {
                $Move = $true
                if (($ListHandle.Items.Count - $SelectedItem - 1) -lt $Count) {$Count = $ListHandle.Items.Count - $SelectedItem - 1}
            } else {
                $Move = $false
                if (($ListHandle.MaxItems - $Line) -lt $Count) {$Count = $ListHandle.MaxItems - $Line}       
            }
        } else {
            if ($SelectedItem -eq 0) {return}
            $One = -1
            if ($SelectedItem -eq $ListHandle.FirstItem) {
                $Move = $true
                if ($SelectedItem -lt ([Math]::Abs([Int]$Count))) {$Count = (-($SelectedItem))}
            } else {
                $Move = $false
                if ($Line -lt ([Math]::Abs([Int]$Count))) {$Count = (-$Line) + 1}
            }
        }

        if ($Move) {
            Set-Selection 1 $Line ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
            Move-List 1 1 ($ListHandle.ListConfig.ListWidth - 3) ($ListHandle.ListConfig.ListHeight - 2) (-$Count)
            $SelectedItem += $Count
            $ListHandle.FirstItem += $Count
            $ListHandle.LastItem += $Count

            $LinePosition = $ListHandle.Position
            $LinePosition.X += 1
            if ($One -eq 1) {
                $LinePosition.Y += $Line - ($Count - $One)
                $LineBuffer = ConvertTo-BufferCellArray ($ListHandle.Items[($SelectedItem - ($Count - $One)) .. $SelectedItem] | Select-Object -ExpandProperty Text) $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
            } else {
                $LinePosition.Y += 1
                $LineBuffer = ConvertTo-BufferCellArray ($ListHandle.Items[($SelectedItem..($SelectedItem - ($Count - $One)))] | Select-Object -ExpandProperty Text) $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
            }
            $LineHandle = New-Buffer $LinePosition $LineBuffer
            Set-Selection 1 $Line ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor
        } else {
            Set-Selection 1 $Line ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.TextColor $PowerTabConfig.Colors.BackColor
            $SelectedItem += $Count
            $Line += $Count
            Set-Selection 1 $Line ($ListHandle.ListConfig.ListWidth - 3) $PowerTabConfig.Colors.SelectedTextColor $PowerTabConfig.Colors.SelectedBackColor
        }
        $ListHandle.SelectedItem = $SelectedItem
        $ListHandle.SelectedLine = $Line

        ## New status buffer
        $StatusHandle.Clear()
        $StatusBuffer = ConvertTo-BufferCellArray "[$($ListHandle.SelectedItem + 1)] $($ListHandle.FirstItem + 1)-$($ListHandle.LastItem + 1) [$($Content.Length)]" `
            $PowerTabConfig.Colors.BorderTextColor $PowerTabConfig.Colors.BorderBackColor
        $StatusHandle = New-Buffer $StatusHandle.Location $StatusBuffer
    }

