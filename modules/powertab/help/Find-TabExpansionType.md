---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Find-TabExpansionType

## SYNOPSIS
Find a Namespace or Type in the tab expansion database.

## SYNTAX

```
Find-TabExpansionType [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will search for .NET Namespaces and Types in the tab expansion database.

Searching for Types works just like tab expansion, thus at least one dot must be specified to include Types in the results.

## EXAMPLES

### Example 1
```powershell
PS C:\> Find-TabExpansionType -Name *.MyType
```

Searches for a Type or Namespace that contains "MyType*"

## PARAMETERS

### -Name
The name pattern to search for, trailing wildcard is not required.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String


## OUTPUTS

### System.Management.Automation.CompletionResult

## NOTES

## RELATED LINKS

[Add-TabExpansionType]()
[Update-TabExpansionType]()
[Remove-TabExpansion]()
