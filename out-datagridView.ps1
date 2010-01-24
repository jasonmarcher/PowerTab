# Function out-datagridView 
# 
# shows piplineinput in a GUI using a datagridView 
# and returns the given field on double-Click or Enter 
# 
# /\/\o\/\/ 2006  
# http://ThePowerShellGuy.com

Function global:out-dataGridView ([String]$ReturnField){  

  # Make DataTable from Input  

  $dt = new-object Data.datatable  
  $First = $true  
  foreach ($item in $input){  
    $DR = $DT.NewRow()  
    $Item.PsObject.get_properties() | foreach {  
      If ($first) {  
        $Col =  new-object Data.DataColumn  
        $Col.ColumnName = $_.Name.ToString()  
        $DT.Columns.Add($Col)       }  
      if ($_.value -eq $null) {  
        $DR.Item($_.Name) = "[empty]"  
      }  
      ElseIf ($_.IsArray) {  
        $DR.Item($_.Name) =[string]::Join($_.value ,";")  
      }  
      Else {  
        $DR.Item($_.Name) = $_.value  
      }  
    }  
    $DT.Rows.Add($DR)  
    $First = $false  
  }  

  # show Datatable in Form   

  $form = new-object Windows.Forms.form   
  $form.Size = new-object System.Drawing.Size @(1000,600)   
  $DG = new-object windows.forms.DataGridView  
  $DG.DataSource = $DT.psObject.baseobject   
  $DG.Dock = [System.Windows.Forms.DockStyle]::Fill 
  $dg.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize 
  $dg.SelectionMode = 'FullRowSelect' 
  $dg.add_DoubleClick({ 
    $script:ret = $this.SelectedRows |% {$_.DataboundItem["$ReturnField"]} 
    $form.Close() 
  }) 
  
  $form.text = "$($myinvocation.line)"  
  $form.KeyPreview = $true 
  $form.Add_KeyDown({ 
    if ($_.KeyCode -eq 'Enter') { 
      $script:ret = $DG.SelectedRows |% {$_.DataboundItem["$ReturnField"]} 
      $form.Close() 
    } 
    ElseIf ($_.KeyCode -eq 'Escape'){ 
      $form.Close() 
    } 
  })  
  
  $form.Controls.Add($DG)  
  $Form.Add_Shown({$form.Activate();$dg.AutoResizeColumns()})  
  $script:ret = $null  
  [void]$form.showdialog()  
  $script:ret 
} 