---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Add-TabExpansionType

## SYNOPSIS
Add type names from an Assembly to the tab expansion database.

## SYNTAX

```
Add-TabExpansionType [-Assembly] <Assembly> [<CommonParameters>]
```

## DESCRIPTION
This command will add a list of .NET type names that are part of an Assembly to the tab expansion database.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Add-Type -Path .\myassembly.dll -PassThru | Select-Object -ExpandProperty Assembly -Unique | Add-TabExpansionType
```

Description

-----------

This example will first load the assembly "myassembly." Then the assembly object is gathered by combining the "-PassThru" parameter of Add-Type with "Select-Object -ExpandProperty" to pipe into Add-TabExpansionType to add the contained types to the tab expansion database.

## PARAMETERS

### -Assembly
The Assembly object represent a .NET assembly with types to be added to the tab expansion database.

```yaml
Type: Assembly
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Reflection.Assembly
You can pipe an Assembly to Add-TabExpansionType to store all type names from the assembly in the tab expansion database.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Update-TabExpansionType]()
[Remove-TabExpansion]()
[Find-TabExpansionType]()
