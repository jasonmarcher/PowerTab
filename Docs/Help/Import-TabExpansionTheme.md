---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Import-TabExpansionTheme

## SYNOPSIS
Loads a PowerTab color theme from a file.

## SYNTAX

### Name (Default)
```
Import-TabExpansionTheme [-Name] <String> [<CommonParameters>]
```

### LiteralPath
```
Import-TabExpansionTheme [-LiteralPath <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will import color settings from a named theme or from a file.

## EXAMPLES

### EXAMPLE 1
```
Import-TabExpansionTheme -Name Digital
```

Description

-----------

This example will load the color theme named "Digital." Tab expansion of theme names is supported.

## PARAMETERS

### -LiteralPath
The path to the file to load the color settings from.

```yaml
Type: String
Parameter Sets: LiteralPath
Aliases: FullName, Path

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the theme to import color settings from.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
You can pipe a string that contains a path to Import-TabExpansionTheme.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Export-TabExpansionTheme]()
