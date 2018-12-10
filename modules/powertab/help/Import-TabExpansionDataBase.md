---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Import-TabExpansionDataBase

## SYNOPSIS
Loads the tab expansion database from a file.

## SYNTAX

```
Import-TabExpansionDataBase [[-LiteralPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will import the tab expansion database from a file.
The current tab expansion database will be replaced by the contents of the specified file.

By default this command will import from the path specified in $PowerTabConfig.Setup.DatabasePath.

## EXAMPLES

### EXAMPLE 1
```
Import-TabExpansionDataBase IsolatedStorage
```

Description

-----------

This example will load the tab expansion database from a file safely stored in Isolated Storage.

## PARAMETERS

### -LiteralPath
The path to the file to load the tab expansion database from.

The special value "IsolatedStorage" can be specified and PowerTab will safely choose a file unique to the current user.

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName, Path

Required: False
Position: 1
Default value: $PowerTabConfig.Setup.DatabasePath
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
You can pipe a string that contains a path to Import-TabExpansionDatabase.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Export-TabExpansionDataBase]()
[New-TabExpansionDataBase]()
