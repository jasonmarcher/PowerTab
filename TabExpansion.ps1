# TabExpansion.ps1 
#
# Replacement of PowerShell default TabExpansion function 
# part of PowerTab TabExpansion library Version 0.99 for PowerShell 1.0
#
# /\/\o\/\/ 2007 
# http://www.ThePowerShellGuy.com

function global:TabExpansion { 
  
    param($line, $lastWord,[switch]$forcelist) 
    

    &{

    $script:TabexpansionHasOutput = $false


    if ($powertabconfig.IgnoreConfirmPreference) {
      $OriginalConfirmPreference = $ConfirmPreference
      $ConfirmPreference = 'High'
    }

    # Load Configuration 

    $dsTabExpansion.Tables['Config'].select("Type <> 'bool'") |% {invoke-expression "`$$($_.name) = ([$($_.type)]'$($_.Value)')"}
    $dsTabExpansion.Tables['Config'].select("Type = 'bool'") |% {invoke-expression "`$$($_.name) = ([bool][int]'$($_.Value)')"}



    # Indicate we are busy 
    if ($TabActivityIndicator) {
      $bottom = $top = $host.ui.rawui.windowposition
      $bottom.X += 5 
      $Rectangle = New-Object management.automation.host.rectangle( $Top , $Bottom)
      $OldBuffer = $Host.UI.RawUI.GetBufferContents($rectangle)
      $message = $host.ui.rawui.NewBufferCellArray([string[]]@('[Tab]'),'Yellow','Blue')
      $host.ui.rawui.SetBufferContents($Top,$message)
      $script:MessageHandle = 1 | select @{name='Top';expression={$top}}, @{name='Buffer';expression={,$OldBuffer}}
    }

    # Detect DoubleTab if enabled
    
    if ($DoubleTabEnabled) {
        Start-Sleep -m 400
        $DoubleTab = ($host.UI.RawUI.KeyAvailable)
    } else {

         $DoubleTab = $DoubleTabLock  
    }

    
    # Check DoubleTab and set Selection Handler

    If ($DoubleTab) {
      $SelectionHandler = $AlternateHandler
    }  Else {
      $SelectionHandler = $DefaultHandler
    }
   
    # Helper variables 

    $_Method = [Management.Automation.PSMemberTypes] 'Method,CodeMethod,ScriptMethod,ParameterizedProperty' 
    $_ScopeNames = @("global", "local", "script", "private") 

    # parse commandline
 
    $LineBlocks = [regex]::Split($line, '[|;]')
    $LastBlock = $LineBlocks[-1]

    # Helper Functions

    Function Resolve-Member ($Object,$pattern) {
        
        # Check for multilevel members 
        
        $levelCount = $pattern.split('.').count
        if ($levelCount -gt 1) { 
            $ofs = '.';$Object += ".$($pattern.split('.')[0..($levelCount -2)])" 
        } 
        
        # Resolve Members
        $val = $Object
        $pat = $pattern.split('.')[($level -1)] + '*' 
        .{
            if ('PSbase' -like $pat){$val + '.PSBase'}
            invoke-expression "Get-Member -inputobject ($val)" | 
            where {
              $n = $_.name
              if (-not $ShowAccessorMethods) { 
                $n -like $pat -and $n -notmatch '^[gs]et_'
              }Else {
                $n -like $pat
              }
            } | foreach { 
                if ($_.MemberType -band $_method) { 
                # Return a method... 
                $val + '.' + $_.name + '(' 
                } else { 
                # Return a property... 
                $val + '.' + $_.name 
                } 
            }
            #
        }  
    
    }

    &{

    #
    # Main tabcompletion , check line for patterns, select completion method and invoke handler
    #
        
    # evaluate last block
    
    switch -regex ($lastBlock)  {
 
        # Handle multilevel property and method expansion on simple () Blocks  

        '(^| )\((.+)\)\.(.*)' { 
          &{ trap {continue}
            Resolve-Member -Object "($($matches[2]))" -Pattern $matches[3] |
              Invoke-TabItemSelector $lastBlock -S $SelectionHandler |% {
                if ($_.indexof('"') -ge 0 ) {
                  ([regex]::Split($_,'"|'''))[-1].trim()
                }else{
                  if ($_.indexof(' ') -ge 0 ) {
                    ([regex]::Split($_,' '))[-1].trim()
                }else{
                  $_
                }
              }
            }
          } 
        } 
        'new-object(.*) (.*)$' { 
            $matched = $matches[2] 
             
            $dots = $matches[2].split(".").count - 1 
                    $res = @() 
                    $res += $global:dsTabExpansion.tables['Types'].select("ns like '$($matched)%' and dc = $($dots + 1)") |  
                        select -uni ns |% {"[$($_.ns)"}
                     
                    if ($dots -gt 0) {
                        $res += $global:dsTabExpansion.tables['Types'].select("name like '$($matched)%' and dc = $dots") |% {"[$($_.name)]"}
                    } 

                    $res  |? {$_} |% {$_  -replace '\[*(.*)\]*','$1'}| Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler -ForceList:$forceList
$script:TabexpansionHasOutput = $true 
           break; 
        } 
    }

    # evaluate last word 
    
    switch -regex ($lastWord)  {

        # Handle inline type search, e.g. new-object .identityreference<tab> or .identityre<tab> (oisin) 

        '^(\[*?)\.(\w+)$' {
          $typeName = $matches[2]
          $types = $dsTabexpansion.tables["Types"]
          $rowFilter = "name like '%.${typeName}%'"
          $selected = $types.select($rowFilter) | 
              foreach {$_["name"] } | Invoke-TabItemSelector $lastword.replace('[','') -Select $SelectionHandler
          if ($matches[1] -eq '[') {$selected = '[' +$selected +']'}
          $selected 
          break;
        }

        # Variable "In-Place" expansion on \[tab]

        '.*(\$[^\\]+)\\$' {
            $val = $ExecutionContext.InvokeCommand.ExpandString($matches[1])
            ($matches[0] -replace ([regex]::Escape( $matches[1])), $val).TrimEnd('\')
        }


        '.*\-\?' {"Get-Help " + $lastword.replace('-?',' -')}
        '^:$' {Get-psdrive |% {$_.name + ':'} | Invoke-TabItemSelector '' -S $SelectionHandler}
        
        # History completion 
        
         '^h_(.*)' {Get-History -count 900 | ? {$_.CommandLine -like "$($matches[1])*"} | foreach-object {$_.CommandLine} | 
           Invoke-TabItemSelector $lastword.replace('h_','') -S $SelectionHandler
         } 

        # About Topics completion 
        
        'about_(.*)' {get-Help "about_$($matches[1])*" |% {$_.name} | Invoke-TabItemSelector $lastWord -S $SelectionHandler}
        
        # DataGrid GUI Shortcuts

        '^a_(.*)' {get-Help "about_$($matches[1])*" | select Name, Synopsis,Length | out-dataGridView name | Foreach-Object {get-help $_}}

         '^w_(.*)' {$global:dsTabExpansion.tables['WMI'].Select("name like 'win32_$($matches[1])%'","name") | out-dataGridView name}
        '^t_(.*)' {$global:dsTabExpansion.tables['Types'].Select("name like '%$($matches[1])%'","name") | out-dataGridView name}
        '^f_' {ls function: | select name | out-dataGridView name}
        '^d_' {ls  | select Mode,LastWriteTime,Length,Name,fullname | out-dataGridView fullname}
        '^g_' {Get-History -Count 100 | out-dataGridView Commandline}
        '^c_(.*)' {$global:dsTabExpansion.Tables['Custom'].select("filter like '$($matches[1])%'","text") | out-dataGridView text}

        # WMI completion                

        '(win32_.*|cim_.*|MSFT_.*)' {
           $global:dsTabExpansion.tables['WMI'].select("name like '$($matches[1])%'") |
             foreach {$_.name}| Invoke-TabItemSelector $lastWord -S $SelectionHandler
           break;
        }

        
        # Handle property and method expansion on variables
        
        '\$(.+)\.(.*)' { 
            Resolve-Member -Object ('$' + $matches[1]) -Pattern $matches[2] | Invoke-TabItemSelector $lastWord -S $SelectionHandler
            break; 
        } 

        # Translate typename to new-Object statement
        
        '(\[.*\])=(\w*)' { 
           "new-Object $($matches[1].replace('[','').replace(']',''))" 
           break; 
        } 

        # Handle Static methods of Types 
        
        '(\[.*\])::(.*)$' { 
            $lasttype = $matches[1] 
            $level = $matches[2].split('.').count 

            if ($level -gt 1) { 
                $lasttype += ('::' + $matches[2].split('.')[0])
                $pat = $matches[2].Substring( ($matches[2].IndexOf('.') + 1) )
                Resolve-Member -Object $lasttype -Pattern $pat | Invoke-TabItemSelector $lastWord -S $SelectionHandler
            } Else {
                $pat = $matches[2].split('.')[($level -1)] + '*' 
                
                invoke-expression "$($matches[1]) | gm -static" | where {$n = $_.name; $n -like $pat -and $n -notmatch '^[ge]et_'} |% { 
                    if ($_.MemberType -band $_Method) { 
                        "${lasttype}::$($_.name)" + '(' 
                    } Else { 
                      "${lasttype}::$($_.name)" 
                    } 
                } | Invoke-TabItemSelector $lastWord -S $SelectionHandler            
               
            }


            break; 
        }
        
        # Handle Static methods of types in Variables 

        '(\$.*)::(.*)$' { 

            $lasttype = $matches[1]
            $gt = ''

            if ((invoke-expression "$lasttype.GetType().Name") -ne 'RuntimeType') {$gt = '.GetType'}
            $level = $matches[2].split('.').count 
            $pat = $matches[2].split('.')[($level -1)] + '*' 
            if ($level -gt 1) {
                $lasttype += ('::' + $matches[2].split('.')[0]) 
                $pat = $matches[2].Substring( ($matches[2].IndexOf('.') + 1) )
                Resolve-Member -Object $lasttype -Pattern $pat | Invoke-TabItemSelector $lastWord -S $SelectionHandler 
            } Else {
                invoke-expression "$($matches[1]) | gm -static" | where {$n = $_.name; $n -like $pat -and $n -notmatch '^[ge]et_'} |% { 
                    if ($_.MemberType -band $_Method) { 
                        "${lasttype}${gt}::$($_.name)" + '(' 
                    } Else { 
                        "${lasttype}${gt}::$($_.name)" 
                    } 
                } | Invoke-TabItemSelector $lastWord.replace('::',"${gt}::") -S $SelectionHandler            
               
            }
            break; 
        }

        # Handle enums and Constructors of Types 

        '(\[.*\]):*$' { 
            $lasttype = $matches[1].split(',')[-1]
            $BaseType = (invoke-expression "$lasttype.basetype.fullname")
            . {
                if ($BaseType -eq 'System.Enum') {
                    $names = invoke-expression "[enum]::getnames($lasttype)" |% {
                        "${lasttype}::$_"
                    }
                    $names | Invoke-TabItemSelector ($lasttype + '::') -S $SelectionHandler
                } else {
                    $Constructors = invoke-expression "$lasttype.GetConstructors()" |% { 
                        $re = New-Object regex('\((.*)\)')
                        $parmTypes = $re.Match($_).groups[1].value.split(',') |% {"[$($_.trim())]"}
                        $Parm = [string]::join(' , ',$parmTypes)
                        "New-Object $($lasttype.trim('[]'))($Parm)".replace('([])','()')
                    }
                    if ($Constructors) {$Constructors | Invoke-TabItemSelector $lasttype -S $SelectionHandler} 
                    Else {Return $lastword}
                }
            } 

            break; 
        }

       # Handle members of Types (runtype) 

        '^(\[.*\]).(\w*)$' { 
            $lasttype = $matches[1].split(',')[-1]
            invoke-expression "$lasttype | gm" | where {$_.name -like "$($matches[2])*"} |% { 
                if ($_.MemberType -band $_Method) { 
                    "$lasttype.$($_.name)" + '(' 
                } Else { 
                    "$lasttype.$($_.name)" 
                } 
            } | Invoke-TabItemSelector $lastWord -S $SelectionHandler
            break; 
        } 



        # Handle namespace and TypeNames 

        '^\[(.*)$' { 
            $matched = $matches[1] 
             
            $dots = $matches[1].split(".").count - 1 
                    $res = @() 
                    $res += $global:dsTabExpansion.tables['Types'].select("ns like '$($matched)%' and dc = $($dots + 1)") |  
                        select -uni ns |% {"[$($_.ns)"}
                     
                    if ($dots -gt 0) {
                        $res += $global:dsTabExpansion.tables['Types'].select("name like '$($matched)%' and dc = $dots") |% {"[$($_.name)]"}
                    } 

                    $res  |? {$_}| Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler -ForceList:$forceList
            break; 
        } 

        # Handle expansions for both "Scope Variable Name" and "Type Variable Names" 

        '(.*^\$)(\w+):(\w*)$' { 
            $type = $matches[2];        # function, variable, etc.. that are not scopes 
            $prefix = $matches[1] + $type;  # $ + function 
            $typeName = $matches[3];            # e.g. in '$function:C', value will be 'C' 
         
            .{if ($_ScopeNames -contains $type) { 
                # Scope Variable Name Expansion 
                foreach ($scopeVariable in 
                    (Get-Variable "$($typeName)*" -Scope $type | Sort-Object name)) { 
                    $prefix + ":" + $scopeVariable.Name 
                } 
            } else { 
                # Type name expansion($function:, $variable, $env: ,etc) 
                foreach ($t in (Get-ChildItem ($type + ":" + $typeName + '*') | Sort-Object name)) { 
                    $prefix + ":" + $t.Name 
                } 
            } } | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler
            break; 
        } 

        # Handle variable name expansion 

        '(.*^\$)(\w*)$' { 
            $prefix = $matches[1] 
            $varName = $matches[2] 
            .{foreach ($v in  get-variable ($varName + '*') -scope 2 |Sort-Object name) { 
                $prefix + $v.name 
            }}| Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler
            break; 
        } 

        # Do completion on parameters 
 
        '^-([\w0-9]*)' {  
            $pat = $matches[1] + '*'  

            $cmdlet = $LastBlock  

            #  Extract the trailing unclosed block  
            if ($cmdlet -match '\{([^\{\}]*)$') {  
                $cmdlet = $matches[1]  
            }  

            # Extract the longest unclosed parenthetical expression...  
            if ($cmdlet -match '\(([^()]*)$') {  
                $cmdlet = $matches[1]  
            }  

            # take the first space separated token of the remaining string  
            # as the command to look up. 
            $script = $cmdlet = $cmdlet.Trim().Split()[0] 

            # now get the info object for it...  
            $cmdlet = @(Get-Command -type 'cmdlet,alias' "[$($cmdlet.Insert(1,']'))")[0]  

            # loop resolving aliases...  
            while ($cmdlet.CommandType -eq 'alias') {  
                $cmdlet = @(Get-Command -type 'cmdlet,alias' "[$($cmdlet.Definition.Insert(1,']'))")[0]  
            } 


            # expand the parameter sets and emit the matching elements  
            .{
		    foreach ($n in $cmdlet.ParameterSets | Select-Object -expand parameters) {  
                	$n = $n.name  
                	if ($n -like $pat) { '-' + $n }  
            	} 

                $tscript = @(Get-Command -type 'Function,ExternalScript,alias' "[$($script.Insert(1,']'))")[0]
                if (! $tscript) {$tscript = @(Get-Command -type 'ExternalScript' $script)[0]}
                if ($tscript) {$script = $tscript}
            while ($script.CommandType -eq 'alias') {  
                $tscript = @(Get-Command -type 'Function,ExternalScript,alias' "[$($script.Definition.Insert(1,']'))")[0]  
                if (! $tscript) {$tscript = @(Get-Command -type 'ExternalScript' $script.Definition)[0]}
                $script = $tscript
            } 
                            
                # Resolve Function Path...  
                If ($script.CommandType -eq 'Function') { 
                    $path = "Function:\$($script.name)"
                } 
                # Resolve Script Path...  
                If ($script.CommandType -eq 'ExternalScript') { 
                    $path = $script.Definition
                } 

                get-ScriptParameters $path |? { $_ -like $pat } |% {"-$_"}


	        }  | sort -unique | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler 
            break;  
        }

        #
        # Completion on Cmdlets, function, aliases and Native commands with defined Shortcuts and Custom additions from DataBase
        #
        
        # Native Commands / scripts in Path

        "(.*)$([regex]::Escape($PowerTabConfig.ShortcutChars.Native))`$" { 
            &{Get-Command -commandType externalscript -Name "$($matches[1])*" |% {$_.Name}
            Get-Command -commandType application -Name "$($matches[1])*" |? {($env:PATHEXT).split(";") -contains $_.extension}|% {$_.Name} } | 
                Invoke-TabItemSelector $lastWord.replace($PowerTabConfig.ShortcutChars.Native ,'') -S $SelectionHandler
            break
        }
        
        #aliases

        "(.*)$([regex]::Escape($PowerTabConfig.ShortcutChars.alias))`$" { 
              &{Get-Command -commandType Alias -Name "[$($matches[1].Insert(1,']'))" |% {$_.Definition}
                $global:dsTabExpansion.Tables['Custom'].select("filter = '$($matches[1])' AND type = 'Alias'") |% {$_.text} 
              }  | Invoke-TabItemSelector $lastWord.replace($PowerTabConfig.ShortcutChars.alias,'') -SelectionHandler $SelectionHandler 
            break
        }

 
        # Custom
        
        "(.*)$([regex]::Escape($PowerTabConfig.ShortcutChars.Custom))`$" { 
            $global:dsTabExpansion.Tables['Custom'].select("filter like '$($matches[1])*' AND type = 'Custom'") |% {$_.text}  | 
                Invoke-TabItemSelector $lastWord.replace($PowerTabConfig.ShortcutChars.alias,'') -SelectionHandler $SelectionHandler 
              
        }

        # Invoke
        
        "(.+)$([regex]::Escape($PowerTabConfig.ShortcutChars.Invoke))`$" { 
            $global:dsTabExpansion.Tables['Custom'].select("filter like '$($matches[1])*' AND type = 'Invoke'") |% {
                $ExecutionContext.InvokeCommand.InvokeScript($_.text)
            }  |  Invoke-TabItemSelector $lastWord.replace($PowerTabConfig.ShortcutChars.Invoke,'') -SelectionHandler $SelectionHandler 
              
        }

        # CallFunction
        
        "(.*)$([regex]::Escape($PowerTabConfig.ShortcutChars.CustomFunction))`$" { 
            if ($PowerTabConfig.CustomFunctionEnabled) {
              $matches[1] |% {
                 $ExecutionContext.InvokeCommand.InvokeScript("$($PowerTabConfig.CustomUserFunction) '$_'")
              }  |  Invoke-TabItemSelector `
                      $lastWord.replace($PowerTabConfig.ShortcutChars.CustomFunction,'') `
                      -SelectionHandler $SelectionHandler 
            }     
        }
        

        # Partial Functions or Commandlets
        
        "(.*)$([regex]::Escape($PowerTabConfig.ShortcutChars.Partial))`$" { 
            &{Get-Command -commandType Function,Filter, Cmdlet -Name "$($matches[1])*"} |
              foreach  {
                $_.Name
              } | Invoke-TabItemSelector $lastWord.replace($PowerTabConfig.ShortcutChars.Partial,'') -SelectionHandler $SelectionHandler
        } 
        
        # Functions or Commandlets on dash
        
        '(.*-.*)' { 
              Get-Command -commandType Function,ExternalScript,Filter, Cmdlet -Name "$($matches[1])*" |% {$_.Name} | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler
        } 

        # Alternate Alias

        '(.+)$' { 
            If ($DoubleTab -or $AliasQuickExpand) {
              &{Get-Command -commandType Alias -Name "[$($matches[1].Insert(1,']'))" |% {$_.Definition}
                $global:dsTabExpansion.Tables['Custom'].select("filter = '$($matches[1])' AND type = 'Alias'") |% {$_.text} 
              }  | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler 
              
            } Else {
              $global:dsTabExpansion.Tables['Custom'].select("filter = '$($matches[1])' AND type = 'Alias'") |% {$_.text}  | 
                Invoke-TabItemSelector  -SelectionHandler $SelectionHandler 
            }
        }
 
        # Completion on Computers in database   
                
        '^\\\\([^\\]*)$' { 
             $global:dsTabExpansion.Tables['Custom'].select("filter like '$($matches[1])%' AND type = 'Computer' ","text") |% {"\\$($_.text)"} | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler
        } 
        
        # Completion on Shares (commented lines without DLL but need admin rights )
        
        '^\\\\([^\\]+)\\([^\\]*)$' { 
             #gwmi win32_share -computer $matches[1] -filter "name like '$($matches[2])%'" | Foreach-Object {"\\$($matches[1])\$($_.name)"}
             #([adsi]"WinNT://$($matches[1])/LanmanServer,FileService" ).psbase.children |? {$_.name -like "$($matches[2])*"}  |% {$_.name}
             [Trinet.Networking.ShareCollection]::GetShares($matches[1]) |? {$_.netname -like "$($matches[2])*"} | sort NetName |% {"\\$($matches[1])\$($_.netname)"} | Invoke-TabItemSelector $lastWord -SelectionHandler $SelectionHandler
        }
    }       # EO switch -regex $lastword
  }  |? {$_} |% {$script:TabexpansionHasOutput = $true;$_}

# Filesystem Completion 

  if ((-not $TabexpansionHasOutput) -and ($FileSystemExpand)) {
            $script:PowerTabfileSystemMode = $true
            $cmdlet = $LastBlock  
            if (-not $SpaceCompleteFileSystem) {$SpaceComplete = $false}
            $DotComplete = $false

            #  Extract the trailing unclosed block  
            if ($cmdlet -match '\{([^\{\}]*)$') {  
                $cmdlet = $matches[1]  
            }  

            # Extract the longest unclosed parenthetical expression...  
            if ($cmdlet -match '\(([^()]*)$') {  
                $cmdlet = $matches[1]  
            }  

            # take the first space separated token of the remaining string  
            # as the command to look up. 
            $script = $cmdlet = $cmdlet.Trim().Split()[0]  

            # now get the info object for it...  
            $cmdlet = @(Get-Command -type 'cmdlet,alias' "[$($cmdlet.Insert(1,']'))")[0]  

            # loop resolving aliases...  
            while ($cmdlet.CommandType -eq 'alias') {  
                $cmdlet = @(Get-Command -type 'cmdlet,alias' "[$($cmdlet.Definition.Insert(1,']'))")[0]  
            }  
      if ($cmdlet -match 'Location') {
        $ChildItems = gci "$lastword*"  |? {$_.PSIsContainer}
      } else {
        $ChildItems = gci "$lastword*"
      }
      if (-not $ChildItems) {$lastword;return}
      #if ((@($childitems).count -eq 1) -and ($lastword.endswith('\')) ) {$childitems = $childitems,@{name='..'}} 
      $PathSlices = [regex]::Split($lastword,'\\|/')
      if ($PathSlices.count -eq 1) {$PathSlices = ,"." + $PathSlices}
      $container = [string]::join('\',$PathSlices[0..($PathSlices.Count -2)])

      $LastPath = ($container + "\$([regex]::Split($lastword,'\\|/|:')[-1])")

      $ChildItems |% {$container + "\" + $_.name}| Invoke-TabItemSelector $lastPath -SelectionHandler $SelectionHandler -return $lastword -ForceList |% {
          $Quote = ''
          $invoke = ''
          if (($_.IndexOf(' ') -ge 0) -and ($_.IndexOf('"') -lt 0) ) {
              if (-not @([char[]]$lastblock |? {$_ -match '"|'''}).count %2) {$quote = '"'}
              if (($lastblock.trim() -eq $lastword)) {$Invoke = '& '}
          }
          "$invoke$quote$_$quote"
      }
  }
  Remove-Variable PowerTabFilesystemmode -Scope script -ea 'SilentlyContinue'
  Remove-Variable TabexpansionHasOutput -Scope script -ea 'SilentlyContinue'
  }

  # remove busy indication on ready or error

  if ($script:MessageHandle){$host.ui.rawui.SetBufferContents($MessageHandle.Top,$MessageHandle.Buffer)
    remove-Variable -Name MessageHandle -Scope script
  }
  
    if ($IgnoreConfirmPreference) {
      $ConfirmPreference = $OriginalConfirmPreference
    }

  trap {
    if ($script:MessageHandle){
      $message = $host.ui.rawui.NewBufferCellArray([string[]]@('[Err]'),'Yellow','Red')
      $host.ui.rawui.SetBufferContents($MessageHandle.Top,$message)
      sleep 1
      $host.ui.rawui.SetBufferContents($MessageHandle.Top,$MessageHandle.Buffer)
      remove-Variable -Name MessageHandle -Scope script
    }
  }

}  # end-function

