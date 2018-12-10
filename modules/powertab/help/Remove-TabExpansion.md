---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Remove-TabExpansion

## SYNOPSIS
Removes items from the tab expansion database.

## SYNTAX

```
Remove-TabExpansion [-Filter] <String> [<CommonParameters>]
```

## DESCRIPTION
This command can remove items from the tab expansion database.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Remove-TabExpansion -Filter h
```

Description

-----------

This example will remove some of the custom filters that turn "h^" into calls to Get-Help

Changes to the database need to be saved using Export-TabExpansionDatabase.

## PARAMETERS

### -Filter
A pattern to match the Filter property of items from the tab expansion database to be removed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Add-TabExpansion]()
[Get-TabExpansion]()
