
# Add Enum Functions
[Void](Add-TabExpansion '|%' '| foreach {$_}' 'Alias')
[Void](Add-TabExpansion '|?' '| where {$_}' 'Alias')
[Void](Add-TabExpansion 'tqb' 'The quick brown fox jumps over the lazy dog')
[Void](Add-TabExpansion 'Localhost' 'Localhost' 'Computer')

# Help Shortcuts
[Void](Add-TabExpansion 'h' 'Get-help $^ -Full')
[Void](Add-TabExpansion 'h' 'Get-help $^ -Detailed')
[Void](Add-TabExpansion 'h' 'Get-help $^ -Examples')

# Font Selection
#[Void]((New-Object System.Drawing.Text.InstalledFontCollection).Families | ForEach-Object { Add-TabExpansion 'FontFamily' $_.name })

# Invoke ShortCuts
[Void](Add-TabExpansion 'now' 'Get-Date' 'Invoke')
[Void](Add-TabExpansion 'date' 'Get-Date -date' 'Invoke')
[Void](Add-TabExpansion 'time' 'Get-Date -time' 'Invoke')