@{
	## Module Info
	ModuleVersion      = '0.99.6.0'
	Description        = 'PowerTab Module'
	GUID               = '64c85865-df87-4bd6-bccd-ea294dc335b3'

	## Module Components
	ScriptsToProcess   = @()
	ModuleToProcess    = @("PowerTab.psm1")
	TypesToProcess     = @()
	FormatsToProcess   = @("TabExpansion.Format.ps1xml")
	ModuleList         = @("PowerTab.psm1")
	FileList           = @()

	## Public Interface
	CmdletsToExport    = ''
	FunctionsToExport  = @('*-*')
	VariablesToExport  = @('PowerTabConfig','PowerTabLog')
	AliasesToExport    = '*'

	## Requirements
	PowerShellVersion      = '2.0'
	PowerShellHostName     = ''
	PowerShellHostVersion  = ''
	RequiredModules        = @()
	RequiredAssemblies     = @()
	ProcessorArchitecture  = 'None'
	DotNetFrameworkVersion = '2.0'
	CLRVersion             = '2.0'

	## Author
	Author             = 'Marc "/\/\o\/\/" van Orsouw, Jason Archer'
	CompanyName        = ''
	Copyright          = ''

	## Private Data
	PrivateData        = ''
}
