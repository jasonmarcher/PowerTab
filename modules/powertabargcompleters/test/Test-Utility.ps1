using namespace System.Management.Automation

. "$SrcDirectory/utils/Utility.ps1"

function Invoke-Handler {
    param (
        [Parameter(Position = 0)]
        [ScriptBlock]
        $Handler
        ,
        [String]
        $commandName
        ,
        [String]
        $parameterName
        ,
        [String]
        $wordToComplete
        ,
        [PSObject[]]
        $commandAst
        ,
        [Hashtable]
        $fakeBoundParameter
    )

    & $Handler $commandName $parameterName $wordToComplete $commandAst $fakeBoundParameter
}

function RegisterArgumentCompleter {}