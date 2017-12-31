# Installing PowerTab

Before getting started, please download the latest PowerTab version from this site. PowerTab is distributed as a standard PowerShell module in a ZIP package. The following instructions are very similar for other PowerShell modules.

## Installing the PowerTab Module

The first step is to unblock the download package containing PowerTab. This can be done from Windows Explorer by Right-Clicking on **PowerTab-<version>.zip** and selecting **Properties**. Then click on the **Unblock** button near the bottom of the properties dialog. Finally, press **OK**.

The second step is to extract the PowerTab package using your favorite archiving utility to your PowerShell modules folder. The default location for this is `.\WindowsPowerShell\Modules` (relative to your **Documents** folder). You may instead extract PowerTab to another folder on your `$env:PSModulePath`.

There should now be a **PowerTab** folder in your modules folder. PowerTab is now installed and ready to be used.

## Running PowerTab

To run PowerTab, open a PowerShell command prompt (or the shell of your favorite PowerShell editor) and run the following.

```
Import-Module PowerTab
```

With no arguments, PowerTab will offer to run a setup wizard to configure PowerTab. The setup wizard will which will help define a location to save the [PowerTab config file](). The config file is required to persist configuration settings for PowerTab, and cached values for .NET type, WMI class and computer name expansion.

It is not necessary to run the setup wizard or do any additional configuration of PowerTab (though some features will not be available until configured).

## Getting Help

Help for using PowerTab is provided from several sources.

- The wiki pages on the PowerTab Website.
- The main about topic available from the PowerShell console.

```
Get-Help about_PowerTab
```

- Find all of the about topics for PowerTab.

```
Get-Help about_PowerTab*
```

- Find all of the commands available from PowerTab and then view the help for each one.

```
Get-Command -Module PowerTab

## View the help for a specific PowerTab function
Get-Help Update-TabExpansionDatabase
```