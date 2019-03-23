Register-ArgumentCompleter -Native -CommandName powershell -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $Parameters = "-Command","ConfigurationName","-EncodedCommand","-ExecutionPolicy","-File","-Help",
    "-InputFormat","-Mta","-NoExit","-NoLogo","-NonInteractive","-NoProfile","-OutputFormat",
    "-PSConsoleFile","-Sta","-Version","-WindowStyle"
    $Parameters | Where-Object {$_ -like "$wordToComplete*"} |
        NewTabItem -Value {$_} -Text {$_} -ResultType wordToComplete

    <#
    PowerShell[.exe] [-PSConsoleFile <file> | -Version <version>]
    [-NoLogo] [-NoExit] [-Sta] [-Mta] [-NoProfile] [-NonInteractive]
    [-InputFormat {Text | XML}] [-OutputFormat {Text | XML}]
    [-WindowStyle <style>] [-EncodedCommand <Base64EncodedCommand>]
    [-ConfigurationName <string>]
    [-File <filePath> <args>] [-ExecutionPolicy <ExecutionPolicy>]
    [-Command { - | <script-block> [-args <arg-array>]
                    | <string> [<CommandParameters>] } ]

    PowerShell[.exe] -Help | -? | /?
    #>
}