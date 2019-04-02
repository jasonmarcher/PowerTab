# Release Notes

## PowerTab 1.0.0

Features:

- Some compatibility changes for PowerShell Core
  - Removed Intellisense Item Selector
- Console history from PSReadline used if available
- Added support for new parameters
  - Workflow names
  - Get-Help -Parameter
  - *-Event -SourceIdentifier
  - Get-Command -Noun
  - Receive-Job -Location
  - WMI parameters
  - New-Object -ArgumentList (display syntax for constructors)
  - Parameters of type Bool
  - ConvertTo-HTML calculated properties
- Added support for assignments to enum variables
- Added array functions from PowerShell v3.0
- Remove parameters already used for parameter completion
- New History and Trace logs for PowerTab usage
- ConsoleList
  - New color theme based on CMD

Bug Fixes:

- General compatiblity fixes with latest PowerShell versions
  - Fix display issue with TrueType fonts
  - Only loaded commands are shown for PowerShell 3.0 and later
- Compatibility fixes with PowerShell Core and non-Windows OSes
  - NOTE: This is not fully tested but full compatibility is a goal
- Consistency fixes for behavior compared to default PowerShell tab expansion
  - Many small fixes for provider paths
- Get-Command <TAB> now includes scripts from $env:PATH
- PowerTab now recognizes automatic aliases for Get-* commands

Detailed list available here:
https://github.com/jasonmarcher/PowerTab/milestone/1?closed=1

## PowerTab 0.99.6

This release includes a number of stability and performance improvements, as well as some new features. Some help topics have been added to the distribution and more help will be added to the wiki. Please provide feedback on the help/documentation in the discussion forum or issue tracker.

Special thanks to Stephen Mills for his testing efforts and a bunch of fixes submitted.

Features:
- Import-TabExpansionConfig should upgrade old databases
- Support for implied "System" prefix for types
- Support for -Server parameter (Add Server to Parameters to expand list of Computers).
- Errors from PowerTab are now gathered in $PowerTabError instead of the global $Error (Prevent PowerTab errors from ending up in $Error).
- Added some support for reg.exe.
- Added some (static) support for netsh.exe. Future releases will dynamically support switches and commands for netsh.
- Added a few help topics for usage and creating tab expansion handlers.

Bug Fixes:
- Add tab expansion for scripts on System Path
- Fixed several quoting issues for paths.
  - Files and directories with parens not being quoted
  - Quoting incorrectly escaping characters when in single quotes
  - Quoting with $ in name works for first <TAB> attempt, but not second <TAB>
- Performance improvements in several areas.
  - Speed up Update-TabExpansionWmi
  - Cache COM object names for better performance
  - PowerTab 0.99.5.0 Much Slower than 0.99 Beta 2 (MOW)
  - Change how alias is resolved in TabExpansionUtil.ps1
- Doing Import-Module [TAB] twice causes $PowerTabConfig to be $null
- Search for Printer names from more locations
- Changed ConsoleList filtering to filter on beginning of string rather than sub string when filter starts blank (ConsoleList matches list items by substrings).
- Fixed several contexts that did not allow embedded wildcards.
  - Tab Expansion with embeded wildcard not working
  - Get-WMIObject Win32_Proce*or[TAB] returns both Win32_Processor and Win32_Proce*or
  - # History Completion doesn't work with *
- Parse-Manifest Used Before Declared
- Out-DataGridView not working - Typo in TabExpansionUtil.ps1 on line 43
- Fixed some issues with UNC paths.
  - New Function Get-ModulePath removes UNC paths from $Env:PSModulePath
  - Error when completing Server in UNC Path
  - Tab Completion not working for Computers in UNC path if using forward slash //
- Error at startup when localized resource file is missing