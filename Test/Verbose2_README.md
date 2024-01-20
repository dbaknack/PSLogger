## Write-Verbose in PowerShell

By default, verbose messages aren't displayed, but you can change this by changing the value of ```$VerbosePreference``` and the *Verbose* parameter to override the preference value.


This example shows the effect of the ```SilentlyContinue``` value, the default. Without the *Verbose* parameter, nothing is shown in the PowerShell console.
```
Write-Verbose -Message "Verbose message test."
```

In this example, the *Verbose* parameter is used, and the message is then written to the console.
```
Write-Verbose -Message "Verbose message test." -Verbose
```

```
$VerbosePreference = "Continue"
Write-Verbose -Message "Verbose message test."
```
This example uses the *Verbose* parameter with a value of *$false* that overrides the Continue value. The message isn't displayed.
```
Write-Verbose -Message "Verbose message test." -Verbose:$false
```

This example shows the effect of the *Stop* value. The ```$VerbosePreference``` variable is set to *Stop* and the message is displayed. The command is stopped.

```
Write-Verbose -Message "Verbose message test." -Verbose:$false
```