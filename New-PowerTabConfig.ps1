PARAM ($installDir = ((pwd).path),$ConfigurationDir = ($PowerTabConfig.ConfigurationPath))
if (-not $ConfigurationDir) {$ConfigurationDir = (split-path $profile)}
if (-not $global:dsTabExpansion){$global:dsTabExpansion = new-object data.dataset}
&{trap{continue}$global:dsTabExpansion.Tables.Remove('config')}
&{trap{continue}$global:dsTabExpansion.Tables.Remove('Cache')}

$dtConfig = New-Object System.Data.DataTable
[void]$dtConfig.Columns.add('Category',[string])
[void]$dtConfig.Columns.add('Name',[string])
[void]$dtConfig.Columns.add('Value')
[void]$dtConfig.Columns.add('Type')
$dtConfig.TableName = 'Config'

# Add global configuration

@{
  Version  = 'PowerTab version 0.96 Beta 3b'
  DefaultHandler = 'ConsoleList'
  AlternateHandler = 'ConsoleList'
}.getEnumerator() |
  Foreach-Object  {
    $row = $dtConfig.NewRow()
    $row.Name = $_.Name
    $row.Type = 'String'
    $row.Category = 'Global'
    $row.Value = $_.Value
    $dtConfig.Rows.Add($row)
  }
@($dtConfig.select("Name = 'Version'"))[0].Category = 'Version'
# Add Color Configuration 

$Items = `
  'BorderColor',
  'BorderBackColor',
  'BackColor',
  'TextColor',
  'SelectedBackColor',
  'SelectedTextColor',
  'BorderTextColor',
  'FilterColor'

$DefaultColors = `
  'Blue',
  'DarkBlue',
  'DarkGray',
  'Yellow',
  'DarkRed',
  'Red',
  'Yellow',
  'DarkGray'

0..($items.GetUpperBound(0)) |
  Foreach-Object {
    $row = $dtConfig.NewRow()
    $row.Name = $items[$_]
    $row.Category = 'Colors'
    $row.Type = 'ConsoleColor'
    $row.Value = [consolecolor]($DefaultColors[$_])
    $dtConfig.Rows.Add($row)
  }

# Add Setup configuration

@{
  InstallPath = "$installDir"
  ConfigurationPath = "$ConfigurationDir"
  DatabasePath = "$ConfigurationDir"
  DatabaseName = 'TabExpansion.xml'
}.getEnumerator() |
  Foreach-Object  {
    $row = $dtConfig.NewRow()
    $row.Name = $_.Name
    $row.Type = 'String'
    $row.Category = 'Setup'
    $row.Value = $_.Value
    $dtConfig.Rows.Add($row)
  }


# Add ShortCut configuration

@{
  Alias   = '@'
  Partial = '%'
  Native  = '!'
  Invoke  = '&'
  Custom  = '^'
}.getEnumerator() |
  Foreach-Object  {
    $row = $dtConfig.NewRow()
    $row.Name = $_.Name
    $row.Type = 'String'
    $row.Category = 'ShortcutChars'
    $row.Value = $_.Value
    $dtConfig.Rows.Add($row)
  }

$al = New-Object Collections.ArrayList
$al.AddRange((
  @{Enabled = $True},
  @{ShowBanner = $True},
  @{AliasQuickExpand = $True},
  @{FileSystemExpand = $True},
  @{AutoExpandOnDot = $True},
  @{AutoExpandOnBackSlash = $True},
  @{DoubleBorder = $True},
  @{DoubleTabEnabled = $False},
  @{DoubleTabLock = $False},
  @{CloseListOnEmptyFilter = $True},
  @{SpaceComplete = $True},
  @{DotComplete = $True},
  @{BackSlashComplete = $true}
))
$al = $al |% {$_.getenumerator() |% {$_}}
$al |Foreach-Object  {
    $row = $dtConfig.NewRow()
    $row.Name = $_.Name
    $row.Type = 'bool'
    $row.Category = 'Global'
    $row.Value = [int]($_.Value)
    $dtConfig.Rows.Add($row)
}

$global:dsTabExpansion.Tables.Add($dtConfig)


Export-PowerTabConfig 'PowerTabConfig.xml' $ConfigurationDir -no
Write-host -fore 'Yellow' "Default Config Created in $ConfigurationDir"