echo on > "%~dp0PowertabSetup.ps1:Zone.Identifier:$DATA"
PowerShell -Nologo -noexit -command "set-location '%~dp0' ; &'%~dp0PowertabSetup.ps1'"

