---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Update-TabExpansionDataBase

## SYNOPSIS
Updates the tab expansion database with fresh lists of items.

## SYNTAX

```
Update-TabExpansionDataBase [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command will update all parts of the tab expansion database.
The database stores source information that takes a long time to gather, such as a list of computer names on the network.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Update-TabExpansionDataBase -Confirm
```

Description

-----------

This example will update the tab expansion database, but prompt for each step of the update.

## PARAMETERS

### -Force
Forces an update of the tab expansion database.

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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
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

### None

## NOTES

## RELATED LINKS

[Export-TabExpansionDataBase]()
[Import-TabExpansionDataBase]()
[New-TabExpansionDataBase]()
