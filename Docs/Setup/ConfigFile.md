# Configuration File Location

The settings that control the behavior of PowerTab are persisted in a configuration file. That path to the configuration file is stored in the ConfigurationPath setting of PowerTab.

```
$PowerTabConfig.Setup.ConfigurationPath
```

## Creating a Configuration File

There are three ways to create a new configuration file for PowerTab.


**When Starting PowerTab**

![Configuration File Location Question](PowerTabConfigLocation.png)

The Setup Wizard will help you choose a location to save your configuration file and tab expansion database. The wizard will present several preset choices or allow choosing an arbitrary folder.

- **Profile Directory** - The directory storing the user's PowerShell profile.
- **Installation Directory** - The installation directory of PowerTab.
- **Application Data Directory** - In the user's roaming Application Data directory, a "PowerTab" folder will be created.
- **Isolated Storage** - Stored in .NET's Isolated Storage, see the Isolated Storage wiki page for more information.
- **Other Directory** - Enter in any valid path to a folder where the configuration file and database should be stored.


**Create a new Configuration after Starting PowerTab**

```
New-TabExpansionConfig
Export-TabExpansionConfig "<full path>"
```

Running these two commands will create a fresh collection of settings and export them to the specified path. The path will be saved in `$PowerTabConfig.Setup.ConfigurationPath` if it has not already been set. Also, `$PowerTabConfig.Setup.DatabasePath` will be updated to point to the same folder if not already set.


**Create a Copy of the Existing Configuration**

```
Export-TabExpansionConfig "<full path>"
```

Run this command to export the PowerTab settings to the specified path. The path will be saved in `$PowerTabConfig.Setup.ConfigurationPath` if it has not already been set. Also, `$PowerTabConfig.Setup.DatabasePath` will be updated to point to the same folder if not already set.

## Using an Existing Configuration File

PowerTab has two startup modes, with a configuration and without. If no configuration is specified, the Setup Wizard will prompt to run. To load a configuration file, use one of the following options.


**When Starting PowerTab**

```
Import-Module PowerTab -ArgumentList C:\Users\JASON\PowerTabConfig.xml
```

Pass the full path to a configuration file while starting PowerTab. This will load the configuration and associated tab expansion database while not prompt the user.


**While Running PowerTab**

```
Import-TabExpansionConfig C:\Users\JASON\PowerTabConfig.xml
```

Running this command will replace the current configuration with the specified configuration for the current session, but not the associated tab expansion database. However, the **DatabasePath** setting will be updated and a call to `Import-TabExpansionDatabase` with no arguments will import that database.