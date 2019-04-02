# Host Support

**Important:**  The information on this page may be out of date.

## PowerTab Support

Host Name | PowerTab Support | Notes
--------- | ---------------- | -----
PowerShell.exe | Yes | Works always, if the command line has changed since last pressing TAB.
PowerShell ISE | Yes | Works always, if the command line has changed since last pressing TAB.
PoshConsole | Yes | 
PowerShell Plus | Partial | Works when expanding the first word or element of a command line. Built-in intellisense afterward.
PowerGUI (embedded) | No | Only supports built-in intellisense, does not call PowerTab at all.
All Other Hosts | Not Tested | If a PowerShell host invokes the built-in tab expansion function of PowerShell, then PowerTab should work on that host.

## Item Selector Support

Host Name | ConsoleList | Default
--------- | ----------- | -------
PowerShell.exe | Yes | Yes
PowerShell ISE |  | Yes
PoshConsole |  | Yes
PowerShell Plus | Yes | Yes
PowerGUI (embedded) |  | ???
All Other Hosts |  | Yes