# Add Enum Functions

  [void](add-tabExpansion '|%' '| foreach {$_}' 'Alias')
  [void](add-tabExpansion '|?' '| where {$_}' 'Alias')
  [void](add-tabExpansion 'cc' "@{name='';expression={}}")
  [void](add-tabExpansion 'cc' "@{Label='';expression={}}")
  [void](add-tabExpansion 'cc' "@{Label='';expression={};Width=10}")
  [void](add-tabExpansion 'tqb' 'The quick brown fox jumps over the lazy dog')
  [void](add-tabExpansion 'Localhost' 'Localhost' 'Computer')
  [void](add-tabExpansion 'ate' 'Add-Tabexpansion')
  [void](add-tabExpansion 'rte' 'Refresh-TabExpansion' )
  [void](add-tabExpansion 'gtcom' 'get-TabExpansionComputer' )
  [void](add-tabExpansion 'gtc' 'get-TabExpansionCustom' )

# Handy Enums

[enum]::GetNames( [System.Management.Automation.ActionPreference] ) |% {  [void]( add-tabExpansion 'ap' $_ )}
[enum]::GetNames( [System.Management.Automation.PSMemberTypes] ) |% {  [void] (add-tabExpansion mt $_ )}
[enum]::getnames([System.Management.AuthenticationLevel])  |% {  [void] (add-tabExpansion al $_) }

# Help Shortcuts

  [void](add-tabExpansion h 'Get-help $^ -Full')
  [void](add-tabExpansion h 'Get-help $^ -Detailed')
  [void](add-tabExpansion h 'Get-help $^ -Examples')

# Font Selection

  #[void]((New-Object System.Drawing.Text.InstalledFontCollection).Families |% { add-tabExpansion FontFamily $_.name })

  [void]($dsTabExpansion.Tables['Custom'].select("type = 'Invoke'") | format-table -auto)

# Invoke ShortCuts

  [void](add-tabExpansion now 'get-date' invoke)
  [void](add-tabExpansion date 'get-date -date' invoke)
  [void](add-tabExpansion time 'get-date -time' invoke)