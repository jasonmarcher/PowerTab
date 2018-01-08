# Release Notes

## PowerTab 1.0.0

- Added #5 - Support array functions for PS 3.0+
- Added #33 - Create basic help
- Added #37 - Add constructor syntax for New-Object
- Added #39 - Add a trace log
- Added #48 - Remove parameters already used for parameter completion
- Added #53 - Add Tab completion on Parameter of type Bool
- Added #54 - Tab expand assignments to variables containing enums
- Added #60 - Setup Wizard should have option to update user's profile
- Added #61 - Add Tab completion on Parameter of type Bool
- Added #62 - More support for WMI parameters
- Added #63 - Add support for Receive-Job -Location <TAB>
- Added #64 - Add support for *-Event -SourceIdentifier <TAB>
- Added #66 - Add support for Get-Command -Noun <TAB>
- Added #69 - Adding support for New-Object -ArgumentList (display syntax for constructors).
- Added #71 - PS v3, support finding workflow names
- Added #73 - Tab support for "Get-Help -Parameter"
- Added #74 - Support for calculated properties with ConvertTo-HTML
- Fixed #76 - Remove Intellisense item selector
- Fixed #77 - Remove Shares.dll
- Added #78 - Add CMD based color theme
- Fixed #6 - In Core handler, avoid call with null CommandInfo
- Fixed #7 - Progress bar possibly hanging
- Fixed #24 - Detecting key state only works on Windows
- Fixed #25 - On closing the menu vertical lines may stay visible in the console
- Fixed #27 - Error with "Get-Content Function:TabExpansion" in PS V4
- Fixed #28 - PSv3: Pointless "Set-Location/Set-LocationEx" auto-complete shows up when I start up a new session
- Fixed #29 - Error in configuration if Profile doesn't exist
- Fixed #30 - Spelling error - LOAD POWERTAB WITH AN EXISTING CONFIG
- Fixed #31 - Powershell v3.0 - typo after tab return only the typo
- Fixed #32 - SHIFT-TAB doesn't work
- Fixed #34 - FileSystem expansion runs if core handler picks up a pattern but does not return a result
- Fixed #36 - Members of scriptblocks that are stored in variables are not shown
- Fixed #38 - Add option for expanding '~' in paths
- Fixed #40 - Broke completion of switch names [regression]
- Fixed #41 - Errors in PowerShell V3 CTP1
- Fixed #42 - Make command history tab completion consistent with default behavior
- Fixed #43 - Autocomplete for user functions stops working
- Fixed #44 - Members of static members of types not working quite right
- Fixed #46 - 0.99.6.0 Issue with networked "Modules" folder
- Fixed #47 - Quoting with Invoke has issues
- Fixed #49 - Alias pointing to script not visible
- Fixed #50 - t_<TAB> is showing "Dummy" types used internally by PowerTab
- Fixed #51 - PowerTab does not recognize automatic aliases for Get-* commands
- Fixed #52 - PowerTab suggesting wrong calculated property for Group-Object bug
- Fixed #57 - PowerTab sometimes forgetting drive name when expanding paths
- Fixed #58 - Add-TabExpansion allows duplicates to be added
- Fixed #65 - Improve understandability of options for some commands
- Fixed #67 - Another failure with completing from root of drive
- Fixed #68 - Internal errors in ConsoleLib
- Fixed #70 - Fixing major performance issue with PS v3. Only look for command names that are already loaded.
- Fixed #72 - Better handling of cleanup code in PS v3 environment
- Fixed - Don't break output for ParameterName handlers that output tab item objects

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