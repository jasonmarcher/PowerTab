Register-ArgumentCompleter -Native -CommandName powershell -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $Parameters = '-Command','-ConfigurationName','-EncodedCommand','-ExecutionPolicy','-File','-Help',
    '-InputFormat','-Mta','-NoExit','-NoLogo','-NonInteractive','-NoProfile','-OutputFormat',
    '-PSConsoleFile','-Sta','-Version','-WindowStyle'

    $LastArgument = $commandAst.CommandElements[-1]

    if ($LastArgument -is [System.Management.Automation.Language.CommandParameterAst]) {
        switch ($LastArgument.ParameterName) {
            'Command' {
                break
            }
            'ConfigurationName' {
                break
            }
            'EncodedCommand' {
                break
            }
            'ExecutionPolicy' {
                'Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted', 'Bypass', 'Undefined' |
                    NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                break
            }
            'File' {
                break
            }
            'InputFormat' {
                'Text', 'Xml' | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                break
            }
            'PSConsoleFile' {
                break
            }
            'Version' {
                '1.0', '2.0', '3.0', '4.0', '5.0', '5.1', '6.0' |
                    NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                break
            }
            'Version' {
                '1.0', '2.0', '3.0', '4.0', '5.0', '5.1', '6.0' |
                    NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                break
            }
            'WindowStyle' {
                'Normal','Minimized','Maximized','Hidden' |
                    NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
                break
            }
            default {
                $Parameters | NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
            }
        }
    } else {
        $Parameters | Where-Object {$_ -like "$wordToComplete*"} |
            NewTabItem -Value {$_} -Text {$_} -ResultType ParameterValue
    }

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