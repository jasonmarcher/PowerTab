$Completion_ItemPropertyName = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $Path = "."
    if ($fakeBoundParameter["Path"]) {
        ## TODO:
        #$Path = Resolve-TabExpansionParameterValue $fakeBoundParameter["Path"]
    }
    Get-ItemProperty -Path $Path -Name "$wordToComplete*" | Get-Member | Where-Object {
        (("Property","NoteProperty") -contains $_.MemberType) -and
        (("PSChildName","PSDrive","PSParentPath","PSPath","PSProvider") -notcontains $_.Name)
    } | Select-Object -ExpandProperty Name -Unique | NewTabItem -Value {$_} -Text {$_} -ResultType ProviderItem
}

RegisterArgumentCompleter -CommandName "Clear-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Copy-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Get-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Get-ItemPropertyValue" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Move-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Remove-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Rename-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName
RegisterArgumentCompleter -CommandName "Set-ItemProperty" -ParameterName "Name" -ScriptBlock $Completion_ItemPropertyName

$Completion_ItemPropertyPropertyType = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    "String","ExpandString","Binary","DWord","MultiString","Qword","Unknown" | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
}

RegisterArgumentCompleter -CommandName "New-ItemProperty" -ParameterName "PropertyType" -ScriptBlock $Completion_ItemPropertyPropertyType