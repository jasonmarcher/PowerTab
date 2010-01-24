PARAM ($installDir = $PowerTabConfig.Setup.InstallPath,$ConfigurationDir = $PowerTabConfig.Setup.ConfigurationPath)

if (-not $installDir) {$InstallDir = (pwd).path}
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
  Version  = 'PowerTab version 0.99 Beta 2'
  DefaultHandler = 'ConsoleList'
  AlternateHandler = 'ConsoleList'
  CustomUserFunction = 'write-warning'
  CustomCompletionChars = ']:)'
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
  CustomFunction  = '#'
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
  @{TabActivityIndicator = $True},
  @{AliasQuickExpand = $False},
  @{FileSystemExpand = $True},
  @{DoubleBorder = $True},
  @{DoubleTabEnabled = $False},
  @{DoubleTabLock = $False},
  @{CloseListOnEmptyFilter = $True},
  @{SpaceComplete = $True},
  @{SpaceCompleteFileSystem = $True},
  @{DotComplete = $True},
  @{BackSlashComplete = $true},
  @{CustomComplete = $True},
  @{AutoExpandOnDot = $True},
  @{AutoExpandOnBackSlash = $True},
  @{CustomFunctionEnabled = $False},
  @{IgnoreConfirmPreference = $False},
  @{ShowAccessorMethods = $True}
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

@{
  MinimumListItems   = '2'
  FastScrollItemcount = '10'
}.getEnumerator() |
  Foreach-Object  {
    $row = $dtConfig.NewRow()
    $row.Name = $_.Name
    $row.Type = 'Int'
    $row.Category = 'Global'
    $row.Value = $_.Value
    $dtConfig.Rows.Add($row)
  }

$global:dsTabExpansion.Tables.Add($dtConfig)


Export-TabExpansionConfig 'PowerTabConfig.xml' $ConfigurationDir -no
Write-host -fore 'Yellow' "Default Config Created in $ConfigurationDir"