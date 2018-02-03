---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Get-TabExpansion

## SYNOPSIS
Gets items available in the tab expansion database.

## SYNTAX

```
Get-TabExpansion [[-Filter] <String>] [[-Type] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command retrieves items from the currently loaded tab expansion database.

## EXAMPLES

### EXAMPLE 1
```
Get-TabExpansion -Filter System.* -Type Types
```

Description

-----------

This example will return all .NET types under the System namespace from the tab expansion database.

## PARAMETERS

### -Filter
A pattern to match the filter property of items in the tab expansion database.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### -Type
The collection or collections of items to search.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### PowerTab.TabExpansion.Item

### PowerTab.TabExpansion.COMItem

### PowerTab.TabExpansion.TypeItem

### PowerTab.TabExpansion.WMIItem

## NOTES

## RELATED LINKS

[Add-TabExpansion]()
[Remove-TabExpansion]()
