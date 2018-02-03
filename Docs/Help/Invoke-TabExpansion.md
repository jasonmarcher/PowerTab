---
external help file: TabExpansionCore-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Invoke-TabExpansion

## SYNOPSIS
Invokes the tab expansion logic of PowerTab.

## SYNTAX

```
Invoke-TabExpansion [-Line] <String> [-LastWord] <String> [-ForceList] [<CommonParameters>]
```

## DESCRIPTION
This function should be called just like the built-in TabExpansion() function of PowerShell.

## EXAMPLES

### EXAMPLE 1
```
Invoke-TabExpansion "Get-Process -" "-"
```

Description

-----------

In this example, PowerTab will interpret the query as looking for a parameter name to Get-Process.

## PARAMETERS

### -ForceList
Forces ConsoleList to display the list control regardless of the value of MinimumListItems.
This is intended for recursive tab expansion support.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastWord
Specifies the last word, or the text that should be replaced by tab expansion.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Line
Specifies the whole command line string.

```yaml
Type: String
Parameter Sets: (All)
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

### None

## OUTPUTS

### System.String
Zero, one or more tab expansion results.

## NOTES

## RELATED LINKS

[about_PowerTab]()
