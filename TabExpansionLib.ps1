# TabExpansionLib.ps1
#
# Function Library for PowerTab Tabcompletion 0.99
# 
# /\/\o\/\/ 2007  
# http://ThePowerShellGuy.com

# Load forms library when not loaded 

if (-not ([appdomain]::CurrentDomain.getassemblies() |?  {$_.ManifestModule -like "System.Windows.Forms*"})) {[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")}

# Invoker for TabitemSelectors

Function global:Invoke-TabItemSelector ($LastWord,$SelectionHandler = 'Default',$returnWord,[switch]$forceList) {
    Switch ($SelectionHandler) {
      'Default' {$Input}
      'intellisense'{$Input | Invoke-Intellisense $LastWord}
      'ConsoleList'{$Input | Out-ConsoleList $LastWord $returnWord -ForceList:$forceList}
    }
}


Function global:New-tabExpansionDataBase {
  $global:dsTabExpansion = new-object data.dataset

  $dtCustom = new-object data.datatable
  [VOID]($dtCustom.Columns.add('Filter',[string]))
  [VOID]($dtCustom.Columns.add('Text',[string]))
  [VOID]($dtCustom.Columns.add('Type',[string]))
  $dtCustom.tablename = 'Custom'
  $global:dsTabExpansion.Tables.Add($dtCustom)

  $dtTypes = new-object data.datatable
  [VOID]($dtTypes.Columns.add('Name',[string]))
  [VOID]($dtTypes.Columns.add('DC',[string]))
  [VOID]($dtTypes.Columns.add('NS',[string]))
  $dtTypes.tablename = 'Types'
  $global:dsTabExpansion.Tables.Add($dtTypes)

  $dtWmi = new-object data.datatable
  [VOID]($dtWmi.Columns.add('name',[string]))
  [VOID]($dtWmi.Columns.add('Description',[string]))
  $dtWmi.tablename = 'Wmi'
  $global:dsTabExpansion.Tables.Add($dtWmi)

}

function global:add-tabExpansionEnum ($enum){[enum]::GetNames($enum.trim('[]'))}

Function global:Export-tabExpansionDataBase ($filename = $PowerTabConfig.Setup.DatabaseName ,
                                             $path= $PowerTabConfig.Setup.DatabasePath ,
                                            [switch]$NoMessage){
  $global:dsTabExpansion.WriteXml("$path\$fileName")
  if (-not $nomessage) {Write-host -fore 'Yellow' "Tabexpansion database exported to $path\$fileName"}
}

Function global:Export-tabExpansionConfig ($filename = 'PowerTabConfig.xml',$path = $PowerTabConfig.Setup.ConfigurationPath,[switch]$NoMessage){
  $global:dsTabExpansion.Tables['config'].WriteXml("$path\$fileName")
  if (-not $nomessage) {Write-host -fore 'Yellow' "Configuration exported to $path\$fileName"}
}

Function global:Import-tabExpansionConfig ($filename = 'PowerTabConfig.xml',$path = $PowerTabConfig.Setup.ConfigurationPath,[switch]$NoMessage) {
  if (-not $global:dsTabExpansion){$global:dsTabExpansion = new-object data.dataset}
  &{trap{continue}$global:dsTabExpansion.Tables['Config'].Clear()}
  [void]$global:dsTabExpansion.ReadXml("$path\$fileName",'InferSchema')
  if (-not $nomessage) {Write-host -fore 'Yellow' "Configuration imported from $path\$fileName"}
}

Function global:Import-TabExpansionDataBase($filename = $PowerTabConfig.Setup.DatabaseName ,
                                            $path= $PowerTabConfig.Setup.DatabasePath ,
                                            [switch]$NoMessage){
  $Confpath = $global:dsTabExpansion.Tables['Config'].select("name = 'ConfigurationPath'")[0].value
  $global:dsTabExpansion = new-object data.dataset
  [void]$global:dsTabExpansion.ReadXml("$path\$fileName")
  if (-not $nomessage) {Write-host -fore 'Yellow' "Tabexpansion database imported from $path\$fileName"}
  Import-TabExpansionConfig -path $Confpath -nomessage
}
Function global:Update-TabExpansionTypes {
    $dsTabExpansion.Tables['Types'].clear()
    $assemblies = [appdomain]::CurrentDomain.getassemblies()
    $assemblies | foreach-object {
        $i++; $ass = $_
        [int]$assemblyProgress = ($i * 100) / $assemblies.Length 
        write-progress "Adding Assembly $($_.getName().name):" "$assemblyProgress" -perc $assemblyProgress
        trap{$script:types = $ass.GetExportedTypes() | Where {$_.IsPublic -eq $true};continue};$script:types = $_.GetTypes() | Where {$_.IsPublic -eq $true}
        $script:types | Foreach-Object {$j = 0} {
            $j++; 
            if (($j % 200) -eq 0) { 
                [int]$typeProgress = ($j * 100) / $script:types.Length 
                write-progress  "Adding types percent complete :" "$typeProgress" -perc $typeProgress -id 1 
            } 
            $dc = &{trap{Continue;0};$_.fullName.split(".").count - 1} 
            $ns = $_.namespace 
            [void]$global:dsTabExpansion.tables['Types'].rows.add("$_",$dc,$ns)
        }
    } 

    # Add NameSpaces Without types
    
    $NL = $dsTabExpansion.Tables['Types'] | 
    Foreach {$i = 0}{$i++
        if (($i % 500) -eq 0) { 
            [int]$typeProgress = ($i * 100) / $dsTabExpansion.Tables['Types'].rows.count 
            write-progress  "Adding NameSpaces percent complete :" "$typeProgress" -perc $typeProgress -id 1 
        } 
        $split = [regex]::Split($_.name,'\.')
        if ($split.length -gt 2) {
            0..($split.length - 3) | Foreach {$ofs='.';"$($split[0..($_)])"}
        }
    } | sort -unique
    $nl |% {[void]$global:dsTabExpansion.tables['Types'].rows.add("Dummy",$_.split('.').count ,$_)}
}

Function global:Get-Assembly ($PartialName = '') {
  [appdomain]::CurrentDomain.GetAssemblies() |? {$_.FullName -match $PartialName}
} 
Function global:add-TabExpansionTypes ([System.Reflection.Assembly]$assembly){

    $assembly | foreach-object {
        $i++; $ass = $_
        trap{$script:types = $ass.GetExportedTypes() | Where {$_.IsPublic -eq $true};continue};$script:types = $_.GetTypes() | Where {$_.IsPublic -eq $true}
        $script:types | Foreach-Object {$j = 0} {
            $j++; 
            if (($j % 200) -eq 0) { 
                [int]$typeProgress = ($j * 100) / $script:types.Length 
                write-progress  "Adding types percent complete :" "$typeProgress" -perc $typeProgress -id 1 
            } 
            $dc = &{trap{Continue;0};$_.fullName.split(".").count - 1} 
            $ns = $_.namespace 
            [void]$global:dsTabExpansion.tables['Types'].rows.add("$_",$dc,$ns)
        }
    } 

    # Add NameSpaces Without types
    
    $NL = $dsTabExpansion.Tables['Types'].select("ns = '$($ass.GetName().name)'") | 
    Foreach {$i = 0}{$i++
        if (($i % 500) -eq 0) { 
            [int]$typeProgress = ($i * 100) / $dsTabExpansion.Tables['Types'].rows.count 
            write-progress  "Adding NameSpaces percent complete :" "$typeProgress" -perc $typeProgress -id 1 
        } 
        $split = [regex]::Split($_.name,'\.')
        if ($split.length -gt 2) {
            0..($split.length - 3) | Foreach {$ofs='.';"$($split[0..($_)])"}
        }
    } | sort -unique
    $nl |% {[void]$global:dsTabExpansion.tables['Types'].rows.add("Dummy",$_.split('.').count ,$_)}
}

Function global:Update-TabExpansionWmi {

    $global:dsTabExpansion.Tables['WMI'].clear()
    
    $WmiClass = [WmiClass]'' 
    
    # Set Enumeration Options 
    
    $opt = new-object system.management.EnumerationOptions 
    $opt.EnumerateDeep = $True 
    $opt.UseAmendedQualifiers = $true 
    
    $i = 0 ; write-progress "Adding WMI Classes" "$i"
    $WmiClass.psBase.GetSubclasses($opt) | foreach {
        $i++ ; if ($i%10 -eq 0) {write-progress "Adding WMI Classes" "$i"} 
        [void]$global:dsTabExpansion.tables['WMI'].rows.add($_.name,($_.psbase.Qualifiers |? {$_.Name -eq 'description'} |% {$_.Value}))
    }
    write-progress "Adding WMI Classes" "$i" -Completed
}

Function global:add-tabExpansion ([string]$filter,[string]$Text,[string]$type = 'Custom'){ 
    $global:dsTabExpansion.Tables['Custom'].Rows.Add($filter,$text,$type) 
}

Function global:Remove-tabExpansion ([string]$filter){ 
    $dsTabExpansion.Tables['custom'].select("Filter LIKE '$Filter'") |% {$_.delete()} 
}

Function global:get-tabExpansion ([string]$filter,$Type = 'Custom'){ 
    if ($type -eq 'Custom'){
      $dsTabExpansion.Tables[$Type].select("Filter LIKE '$Filter'") 
    } Else {
      $dsTabExpansion.Tables[$Type].select("Name LIKE '$Filter'")   
    }
}


Function global:Update-TabExpansion { 
  Update-TabExpansionTypes
  Update-TabExpansionWmi
}
function global:Invoke-TabExpansionEditor {

  $form = new-object "System.Windows.Forms.Form"
  $form.Size = new-object System.Drawing.Size @(500,300)
  $form.text = "PowerTab 0.92 PowerShell TabExpansion library"

  $DG = new-object "System.windows.forms.DataGrid"
  $DG.CaptionText = "Custom TabExpansion DataBase Editor"
  $DG.AllowSorting = $True
  $DG.DataSource = $global:dsTabExpansion.psObject.baseobject
  $DG.Dock = [System.Windows.Forms.DockStyle]::Fill
  $form.Controls.Add($DG)
  $statusbar = new-object System.Windows.Forms.Statusbar
  $statusbar.text = " /\/\o\/\/ 2007 http://thePowerShellGuy.com"
  $form.Controls.Add($Statusbar)
  #show the Form 

  $Form.Add_Shown({$form.Activate();$dg.Expand(0)})
  [void]$form.showdialog() 
}
Function global:add-TabExpansionComputersNetView {
  net view |% {if($_ -match '\\\\(.*?) '){$matches[1]}} |% {add-tabExpansion $_ $_ 'Computer'}
}

Function global:add-TabExpansionComputersOU ([adsi]$ou){
  $Ou.psbase.get_children() | select @{e={$_.cn[0]};n='Name'} |% {add-tabExpansion $_.name $_.name 'Computer'}
}
Function global:get-TabExpansionCustom {
  Write-Host -ForegroundColor 'Yellow' "Current Custom Aliases :"
  $dsTabExpansion.Tables['Custom'].select("type = 'Custom'") | format-table -auto
}
Function global:get-TabExpansionComputer {
  Write-Host -ForegroundColor 'Yellow' "Current Custom Computerlist :"
  $dsTabExpansion.Tables['Custom'].select("type = 'Computer'") | format-table -auto
}

Function global:Add-TabExpansionEnumFromLastError ($Name){
    [void]($Error[0] -match 'to type \"(.*?)\".*are \"(.*?)\"')
    If ($name) {
        $filter = $name
    } else {
        $filter = $matches[1].split('.')[-1]   
    }
    $matches[2].split(',') |% {add-TabExpansion $filter $_.trim('" ')}
}

Function global:Import-TabExpansiontheme ($path){ 
  $theme = Import-Csv $path
  $PowerTabConfig.Colors.ImportTheme($theme) 
}
Function global:Export-TabExpansiontheme ($path){ 
  $PowerTabConfig.Colors.ExportTheme() | Export-Csv -noType $path  
}