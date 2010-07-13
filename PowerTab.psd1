@{
	
	## Module Info
	ModuleVersion      = '0.99.3.0'
	Description        = 'PowerTab Module'
	GUID               = '64c85865-df87-4bd6-bccd-ea294dc335b3'
	
	## Module Components
	ScriptsToProcess   = @()
	NestedModules      = @("PowerTab.psm1")
	TypesToProcess     = @()
	FormatsToProcess   = @()
	ModuleList         = @("PowerTab.psm1")
	FileList           = @()
	
	## Public Interface
	CmdletsToExport    = ''
	FunctionsToExport  = @('*-TabExpansion*')
	VariablesToExport  = @('PowerTabConfig')
	AliasesToExport    = ''
	
	## Requirements
	PowerShellVersion      = '2.0'
	PowerShellHostName     = ''
	PowerShellHostVersion  = ''
	RequiredModules        = @()
	RequiredAssemblies     = @("Shares.dll")
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