# PowerTab 0.99 Beta 2

for install or upgrade just put all files in powertab instalation directory then doubleclick setup.cmd in explorer
or start PowerTabSetup.ps1 script from PowerShell



### Instalation ### 


On first installation you can just start PowerTabSetup.PS1 to Install / Configure PowerTab

follow the instructions or just say yes to all questions (next next next setup)

you will need to Dot Source the Setup to directly start using the new tabcompletion functions
if you start it normaly the setup will work fine but you need to start a new PowerShell session to use it.
this looks like this :

. ./PowerTabSetup.PS1

### Upgrading from former versions ###

# full setup

the most simple way to upgrade is to copy all files to the installation directory and run PowerTabSetup.ps1 again
then after setup remove the addition to the profile from the former version.

# keep database

you do not have to overwrite the database, but a new table needs to be added, so if you do not create one setup will ask to add the config table

# Manual 

you can run 

New-PowerTabConfig.ps1 to update the database




For more Information and examples about PowerTab Tabexpansions see :

The PowerTab PowerShell Tab Extension Overview Page

http://thepowershellguy.com/blogs/posh/pages/powertab.aspx

This script makes use of the Shares.DLL from the following C# library
 
http://www.codeproject.com/cs/internet/networkshares.asp

you can find the complete source in the Lib directory

Enjoy, Greetings /\/\o\/\/

http://ThePowerShellGuy.com
