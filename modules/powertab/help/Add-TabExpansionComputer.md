---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Add-TabExpansionComputer

## SYNOPSIS
Adds computer names to the tab expansion database.

## SYNTAX

### Name (Default)
```
Add-TabExpansionComputer [-ComputerName] <String> [<CommonParameters>]
```

### OU
```
Add-TabExpansionComputer [-OU] <DirectoryEntry> [<CommonParameters>]
```

### NetView
```
Add-TabExpansionComputer [-NetView] [<CommonParameters>]
```

## DESCRIPTION
This command is used to add computer names to the tab expansion database.
The computer names can then be used to tab expand contexts that use computer names, for example the -ComputerName parameter.

Changes to the database need to be saved using Export-TabExpansionDatabase.

## EXAMPLES

### EXAMPLE 1
```
Get-Content .\servers.txt | Add-TabExpansionComputer
```

Description

-----------

In this example a list of computer names is stored in the "servers.txt" file.
Then the file is read and the names added to the tab expansion database by piping into this command.

### EXAMPLE 2
```
Add-TabExpansionComputer -NetView
```

Description

-----------

This example will use "net view" to add a list of computer names to the tab expansion database.
This is the same command used by Update-TabExpansionDatabase

NOTE: It is strongly suggest to run Remove-TabExpansionComputer before this command to prevent duplicate entries in the tab expansion database.

## PARAMETERS

### -ComputerName
A computer name to add to the database.

```yaml
Type: String
Parameter Sets: Name
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NetView
Causes this command to gather computer names using "net view".

```yaml
Type: SwitchParameter
Parameter Sets: NetView
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OU
Specifies an Organizational Unit (OU) from Active Directory containing computers that should be added to the tab expansion database.

```yaml
Type: DirectoryEntry
Parameter Sets: OU
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

### System.DirectoryServices.DirectoryEntry
You can pipe a DirectoryEntry to Add-TabExpansionComputer to store all computer names that are a part of an OU in the tab expansion database.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Remove-TabExpansionComputer]()

