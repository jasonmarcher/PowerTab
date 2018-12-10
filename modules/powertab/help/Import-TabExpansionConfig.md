---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Import-TabExpansionConfig

## SYNOPSIS
Loads the PowerTab configuration from a file.

## SYNTAX

```
Import-TabExpansionConfig [[-LiteralPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will import the PowerTab configuration settings from a file.
The current onfiguration will be replaced by the contents of the config file.

By default this command will import from the path specified in $PowerTabConfig.Setup.ConfigurationPath.

## EXAMPLES

### EXAMPLE 1
```
Import-TabExpansionConfig
```

Description

-----------

This example will reset the current configuration to the last saved set of settings from the PowerTab config file.

## PARAMETERS

### -LiteralPath
The path to the file to load the PowerTab configuration from.

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
You can pipe a string that contains a path to Import-TabExpansionConfig.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Export-TabExpansionConfig]()
[New-TabExpansionConfig]()
