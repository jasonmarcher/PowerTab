---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Export-TabExpansionConfig

## SYNOPSIS
Saves the current PowerTab configuration to a file.

## SYNTAX

```
Export-TabExpansionConfig [[-LiteralPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will export the PowerTab configuration settings to a file.
Configuration changes are not automatically saved and must be manually exported.

By default this command will export to the path specified in $PowerTabConfig.Setup.ConfigurationPath.

## EXAMPLES

### EXAMPLE 1
```
Export-TabExpansionConfig (Join-Path $HOME "Config.xml")
```

Description

-----------

This example will save the PowerTab configuration to an XML file in the home directory of the current user.

## PARAMETERS

### -LiteralPath
The path to the file to store the PowerTab configuration in.

The special value "IsolatedStorage" can be specified and PowerTab will safely choose a file unique to the current user.

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

### System.String
You can pipe a string that contains a path to Export-TabExpansionConfig.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Import-TabExpansionConfig]()
[New-TabExpansionConfig]()
