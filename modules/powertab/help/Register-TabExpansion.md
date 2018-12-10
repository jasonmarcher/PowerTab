---
external help file: TabExpansionLib-Help.xml
Module Name: PowerTab
online version:
schema: 2.0.0
---

# Register-TabExpansion

## SYNOPSIS
Registers a handler to take part in tab expansion of parameters and parameter values.

## SYNTAX

```
Register-TabExpansion [-Name] <String> [-Handler] <ScriptBlock> [-Type <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
This command allows for the creation of handlers that extend PowerTab to support unique command or parameter usage.

## EXAMPLES

### EXAMPLE 1
```
Register-TabExpansion "Get-Service" -Type Command {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)

    $Argument = $Context.Argument
    switch -exact ($Context.Parameter) {
        'DisplayName' {
            $TabExpansionHasOutput.Value = $true 
            Get-Service -DisplayName "*$Argument*" |
                Select-Object -ExpandProperty DisplayName
        }
        'Name' {
            $TabExpansionHasOutput.Value = $true
            Get-Service -Name "$Argument*" |
                Select-Object -ExpandProperty Name
        }
    }
}
```

Description

-----------

This example is simplified from the Get-Service handler in PowerTab.
Please read about_PowerTab_handlers for a more indepth explanation.

## PARAMETERS

### -Force
Register the new handler even if a similar handler already exists.

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

### -Handler
A ScriptBlock defining the body of the handler.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The name of the command or parameter that the handler will target.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Type
The type of handler to register.
Valid values for Type are:

-- Command: Handler will have first chance at any expansion involving the registered command.
-- Parameter: Handler will respond to all uses of a parameter not already handled by a Command handler.
-- ParameterName: Special use handler to provide parameter names for non-PowerShell commands.
-- CommandInfo: Special use handler to tell PowerTab about positional parameters and enumeration values.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Command
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Collections.Hashtable
You can pipe a hashtable that contains keys named "Name" or "Handler to Register-TabExpansion.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[about_PowerTab_handlers]()
[about_PowerTab]()
