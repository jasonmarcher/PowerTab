---
external help file: TabExpansionLib-help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# New-TabItem

## SYNOPSIS
Helper function to create CompletionResult objects.

## SYNTAX

```
New-TabItem [-Value] <String> [[-Text] <String>] [-Type <String>] [-ResultType <CompletionResultType>]
 [-ToolTip <String>] [<CommonParameters>]
```

## DESCRIPTION
This command will create CompletionResult objects for use with any tab item selector.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Process | New-TabItem -Value {$_.Id} -Text {$_.Name}
```

Basic example of how to convert complex objects into tab expansion results.

## PARAMETERS

### -ResultType
Type of result, can controls icon and format display in GUI item selectors.

```yaml
Type: CompletionResultType
Parameter Sets: (All)
Aliases:
Accepted values: Text, History, Command, ProviderItem, ProviderContainer, Property, Method, ParameterName, ParameterValue, Variable, Namespace, Type, Keyword, DynamicKeyword

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text
User friendly text to display in list of results.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ToolTip
Tooltip for item, used in GUI based item selectors.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Type
DEPRECATED.  Included only for backward compatibility.  Use -ResultType instead.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The actual value to fulfill tab expansion.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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
