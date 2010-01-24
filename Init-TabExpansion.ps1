param ($ConfigurationLocation = $PowerTabConfig.Setup.ConfigurationPath,[switch]$NoWarning)

$InitScriptVersion = 'PowerTab version 0.99 Beta 2' 

if ($global:PowerTabConfig -and (-not $NoWarning)) {
  Write-Warning "$($PowerTabConfig.Version) was allready loaded`n re-Initializing configuration from :`n $ConfigurationLocation`n`n"
}

# Read Configuration 

$filename = 'PowerTabConfig.xml'
$global:dsTabExpansion = new-object data.dataset

[void]$global:dsTabExpansion.ReadXml("$ConfigurationLocation\$fileName",'InferSchema')

$installDir = $global:dsTabExpansion.tables['Config'].select("Name = 'InstallPath'")[0].value
$DatabaseName = $global:dsTabExpansion.tables['Config'].select("Name = 'DatabaseName'")[0].value
$DatabasePath = $global:dsTabExpansion.tables['Config'].select("Name = 'DatabasePath'")[0].value

# Load the PowerTab Utility Functions

. "$installDir\TabExpansionLib.ps1" 

# Load TabExpansion database

Import-TabExpansionDataBase $DatabaseName $DatabasePath -nomessage
Import-TabExpansionConfig 'PowerTabConfig.xml' $ConfigurationLocation -no

if ($global:dsTabExpansion.Tables['Config'].select("Name = 'Version'")[0].value -ne $InitScriptVersion) {
  write-Warning "Error loading PowerTab configuration !, Configuration of $($global:dsTabExpansion.Tables['Config'].select(""Name = 'Version'"")[0].value) found while $InitScriptVersion was expected ! If powertab library files are updated please run PowerTabsetup.ps1 again to update configuration`n"
  write-Host "`n If you started Setup.cmd to upgrade Powertab this is an expected situation, when you continue the powertab setup process will start automaticly and update the the current configurationdatabase to the right version`n"
  Write-Warning "PowerTab will not function correctly until the Configuration is updated !"
  Write-Host "If only the files are updated, Please start Setup.cmd or run PowerTabSetup.ps1 to update the Configuration also"

  read-host "press enter to continue"
}
# Backup current tabexpansion function 

&{trap{continue}$global:dsTabExpansion.Tables.Remove('Cache')}
$dtCache = New-Object System.Data.DataTable
[void]$dtCache.Columns.add('Name',[string])
[void]$dtCache.Columns.add('Value')
$dtCache.TableName = 'Cache'
$row = $dtCache.newrow()
$row.Name = 'OldTabexpansion'
$oldTabexpansion = gc function:\tabexpansion
$row.Value = $oldTabexpansion
$dtCache.rows.add($row)
$global:dsTabExpansion.Tables.Add($dtCache)

$global:PowerTabConfig = new-object object

Add-Member -InputObject $Global:PowerTabConfig -MemberType NoteProperty -Name Version -Value $global:dsTabExpansion.Tables['Config'].select("Name = 'Version'")[0].value
# Add enable scriptproperties

    add-member `
      -InputObject $PowerTabConfig `
      -MemberType ScriptProperty `
      -Name Enabled `
      -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$v = `$dsTabExpansion.Tables['Config'].Select(""Name = 'Enabled'"")[0]
            if (`$v.type -eq 'bool'){[bool][int]`$v.Value}
            else {[$($_.type)](`$v.value)}
         ") `
      -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap{write-warning `$_;continue}
                `$val = [bool]`$args[0]
                 `$val = [int]`$val
                `$dsTabExpansion.Tables['Config'].Select(""Name = 'Enabled'"")[0].Value = `$val
                 if ([bool]`$val){`$path = `$dsTabExpansion.Tables['Config'].Select(""Name = 'InstallPath'"")[0].value
                   . ""`$path\TabExpansion.ps1""
                 }else{sc function:\tabexpansion `$global:dsTabExpansion.Tables['Cache'].select(""name = 'OldTabExpansion'"")[0].value}") `
      -Force

$PowerTabColors = new-object object
Add-Member -InputObject $Global:PowerTabConfig -MemberType NoteProperty -Name Colors -Value $PowerTabColors
Add-Member -InputObject $global:PowerTabConfig.Colors -MemberType ScriptMethod -name ToString -Value {"{PowerTab Color Configuration}"} -Force

$PowerTabShortCuts = new-object object
Add-Member -InputObject $PowerTabShortCuts -MemberType ScriptMethod -name ToString -Value {"{PowerTab Shortcut Characters}"} -Force
Add-Member -InputObject $Global:PowerTabConfig -MemberType NoteProperty -Name ShortcutChars -Value $PowerTabShortcuts

$PowerTabSetup = new-object object
Add-Member -InputObject $PowerTabSetup -MemberType ScriptMethod -name ToString -Value {"{PowerTab Setup Data}"} -Force
Add-Member -InputObject $Global:PowerTabConfig -MemberType NoteProperty -Name Setup -Value $PowerTabSetup

# Make Global properties on Config Object

$global:dsTabExpansion.Tables['Config'].select("Category = 'Global'") | 
  Foreach-Object {
    add-member `
      -InputObject $PowerTabConfig `
      -MemberType ScriptProperty `
      -Name $_.Name `
      -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$v = `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0]
            if (`$v.type -eq 'bool'){[bool][int]`$v.Value}
            else {[$($_.type)](`$v.value)}
         ") `
      -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap{write-warning `$_;continue}
                `$val = [$($_.type)]`$args[0]
                 if ( '$($_.type)' -eq 'bool' ) {`$val = [int]`$val}
                `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value = `$val") `
      -Force
  }




# Make Setup properties on Config Object

$global:dsTabExpansion.Tables['Config'].select("Category = 'Setup'") | 
  Foreach-Object {
    add-member `
      -InputObject $PowerTabConfig.setup `
      -MemberType ScriptProperty `
      -Name $_.Name `
      -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
            "`$v = `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0]
            if (`$v.type -eq 'bool'){[bool][int]`$v.Value}
            else {[$($_.type)](`$v.value)}
         ") `
      -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap{write-warning `$_;continue}
                `$val = [$($_.type)]`$args[0]
                 if ( '$($_.type)' -eq 'bool' ) {`$val = [int]`$val}
                `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value = `$val") `
      -Force
  }


# Make Color properties on Config Object

$global:dsTabExpansion.Tables['Config'].select("Category = 'Colors'") | 
  Foreach-Object {
    add-member `
      -InputObject $PowerTabConfig.Colors `
      -MemberType ScriptProperty `
      -Name $_.Name `
      -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
             "`$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value") `
      -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap{write-warning `$_;continue}
                `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value = [consolecolor]`$args[0]") `
      -Force
  }
  Add-Member `
      -InputObject $PowerTabConfig.Colors `
      -MemberType ScriptMethod `
      -name ExportTheme `
      -Value {$this | gm -MemberType ScriptProperty | select @{name='Name';expression={$_.name}},@{name='Color';expression={$PowerTabConfig.colors."$($_.name)"}}} 
 
  Add-Member `
      -InputObject $PowerTabConfig.Colors `
      -MemberType ScriptMethod `
      -name ImportTheme `
      -Value {$args[0] |% {$PowerTabConfig.Colors."$($_.name)" = $_.Color}} 

# Make Shortcut properties on Config Object

$global:dsTabExpansion.Tables['Config'].select("Category = 'ShortcutChars'") | 
  Foreach-Object {
    add-member `
      -InputObject $PowerTabConfig.ShortcutChars `
      -MemberType ScriptProperty `
      -Name $_.Name `
      -Value $ExecutionContext.InvokeCommand.NewScriptBlock(
             "`$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value") `
      -SecondValue $ExecutionContext.InvokeCommand.NewScriptBlock(
                "trap{write-warning `$_;continue}
                `$dsTabExpansion.Tables['Config'].Select(""Name = '$($_.name)'"")[0].Value = `$args[0]") `
      -Force
  }



# load other functions 

if ($PowerTabConfig.Enabled) {
  . "$installDir\TabExpansion.ps1"          # Load Main Tabcompletion function
}
. "$installDir\Out-DataGridView.ps1"      # Used for GUI TabExpansion
. "$installDir\ConsoleLib.ps1"            # Used for RawUi ConsoleList border
. "$installDir\Get-ScriptParameters.ps1"  # Get Parameters of Scripts


# load External Library for Share Enumeration

[void][System.Reflection.Assembly]::LoadFile("$installDir\shares.dll")

if ($PowerTabConfig.ShowBanner) {
Write-Host -f 'Yellow' "$($PowerTabConfig.Version) PowerShell TabExpansion library "
Write-Host -f 'Blue' "/\/\o\/\/ 2007 http://thePowerShellGuy.com"
Write-Host -f 'Yellow' "PowerTab Tabexpansion additions enabled : $($PowerTabConfig.Enabled)"
}

