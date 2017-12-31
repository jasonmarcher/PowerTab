# Tab Expansion Database

The tab expansion database stores items to improve the performance of PowerTab. Looking up some kinds of items can take too long to make it worth using tab expansion, so PowerTab stores those items for quick look ups. Any tab expansion context setup to use the database will only query the database in oder to prevent excessive wait times. The database needs to be persisted to a file for use in future PowerShell sessions, that path is stored in the **DatabasePath** setting of PowerTab.

```
$PowerTabConfig.Setup.DatabasePath
```

## Creating a new Database

There are several ways to create and save a tab expansion database. PowerTab will always guarantee that a tab expansion database is available while running, though it may be empty. The database will only be automatically saved when running the Setup Wizard, or when passing a non-existent path to PowerTab at startup.


**When Starting PowerTab**

The tab expansion database will be created when PowerTab is started without a path to a configuration file, even if you do not run the Setup Wizard. However, the database will not be populated with any items. When running the Setup Wizard, you will be prompted to populated the tab expansion database. The location of the database created by the Setup Wizard will be the same folder as the configuration file, please see the section on [creating a configuration file from the Setup Wizard](ConfigFile.md#creating-a-configuration-file).


**Create a new Database after Starting PowerTab**

```
New-TabExpansionDatabase
Update-TabExpansionDatabase  ## optional
Export-TabExpansionDatabase "<full path>"
```

The first and last command will create a new database and save it to the specified path. The second command will save a list of the current .NET types, WMI class names, and computer names. You can run that command with the `-Confirm` parameter to be prompted for each of those steps. When exporting the database, the path will be saved in `$PowerTabConfig.Setup.DatabasePath` if it has not already been set.


**Create a Copy of the Existing Database**

```
Export-TabExpansionDatabase "<full path>"
```

Run this command to export the tab expansion database to the specified path. The path will be saved in `$PowerTabConfig.Setup.DatabasePath` if it has not already been set.

## Using an Existing Database

PowerTab has two startup modes, with a configuration and without. If no configuration is specified, the Setup Wizard will prompt to run. Each configuration file has an associated (but not necessarily unique) tab expansion database. To load a database, use one of the following options.


**When Starting PowerTab**

```
Import-Module PowerTab -ArgumentList C:\Users\JASON\PowerTabConfig.xml
```

Pass the full path to a configuration file while starting PowerTab. This will load the configuration and associated tab expansion database while not prompt the user.


**While Running PowerTab**

```
Import-TabExpansionDatabase C:\Users\JASON\TabExpansion.xml
```

Running this command will replace the database in use with the requested database.