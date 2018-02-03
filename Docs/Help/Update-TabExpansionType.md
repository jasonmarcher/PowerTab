---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Update-TabExpansionType

## SYNOPSIS
Updates the tab expansion database with a fresh list of .NET type names.

## SYNTAX

```
Update-TabExpansionType [<CommonParameters>]
```

## DESCRIPTION
This command will update the list of .NET types in the tab expansion database.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Update-TabExpansionType
```

Description

-----------

Updates the list of .NET types.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Add-TabExpansionType]()
[Remove-TabExpansion]()
