---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# New-TabExpansionConfig

## SYNOPSIS
Replaces the PowerTab configuration with default values.

## SYNTAX

```
New-TabExpansionConfig [[-LiteralPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will reset the configuration settings of PowerTab to their default values.

## EXAMPLES

### EXAMPLE 1
```
New-TabExpansionConfig
```

Description

-----------

This example will reset the PowerTab configuration to defaults.

## PARAMETERS

### -LiteralPath
Specifies the value for ConfigurationPath, but a file is not created.

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName, Path

Required: False
Position: 1
Default value: $PowerTabConfig.Setup.ConfigurationPath
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo
You can pipe a FileInfo object (or any object with a path) to New-TabExpansionConfig.

### System.String
You can pipe a string that contains a path to New-TabExpansionConfig.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Export-TabExpansionConfig]()
[Import-TabExpansionConfig]()
