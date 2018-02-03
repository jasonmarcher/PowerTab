---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Export-TabExpansionTheme

## SYNOPSIS
Saves the current PowerTab color theme to a file.

## SYNTAX

### Name (Default)
```
Export-TabExpansionTheme [-Name] <String> [<CommonParameters>]
```

### LiteralPath
```
Export-TabExpansionTheme [-LiteralPath <String>] [<CommonParameters>]
```

## DESCRIPTION
This command can be used to save the current color settings as a named theme for PowerTab, or to a separate file.
Current color settings are stored in the PowerTab configuration settings.

## EXAMPLES

### EXAMPLE 1
```
Export-TabExpansionTheme -Name TheColorsDuke
```

Description

-----------

This example will create a new named color theme.
Themes are stored in files within the install location of PowerTab.

## PARAMETERS

### -LiteralPath
The path to the file to store the color settings in.

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
Specifies the name of the theme to save the current color settings to.
Themes can be imported by name.

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
You can pipe a string that contains a path to Export-TabExpansionTheme.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Import-TabExpansionTheme]()
