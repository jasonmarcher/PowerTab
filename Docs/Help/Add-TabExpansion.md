---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Add-TabExpansion

## SYNOPSIS
Adds an item to the tab expansion database.

## SYNTAX

```
Add-TabExpansion [-Filter] <String> [-Text] <String> [[-Type] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command is used to add items to the tab expansion database.

Items for COM objects, .NET types, or WMI objects can not be added using this command.
Please use the specific commands for those items.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Add-TabExpansion -Filter "test" -Text "Your first custom tab expansion was a success!" -Type Custom
```

Description

-----------

This example will add a custom pattern that will turn "test^" into the above sentence after pressing the tab key.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## PARAMETERS

### -Filter
The text to match against user input.

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

### -Text
The output text to present to the user.
This value is often the same as Filter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
The specific feature of PowerTab that the item is to be associated with.

-- Alias: The item defines an alias that does not exist for a PowerShell command or application.
-- Custom: An item for the custom expansion character(^).
-- Computer: The item represents a computer name.
-- Invoke: An item for the invoke character (&).

Items for COM objects, .NET types, or WMI objects can not be added using this command.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Custom
Accept pipeline input: False
Accept wildcard characters: False
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

[Get-TabExpansion]()
[Remove-TabExpansion]()
