Import-Module "./PSLogger"
# at this stage, the module is imported
$PSLogger = PSLogger -InitializeLog
$PSLogger.UtilityReloadConfiguration('SeedValue')
$PSLogger.Message("this is a test")
$PSLogger.UtilityTestFilePath("./")
$PSLogger.UtilityReloadConfiguration(@("Headings"))
$PSLogger.GetConfiguration("Headings")
$PSLogger.Message("This is a new message")
Get-Module
Remove-Module PSLogger

PSLogger_Class



$PSLogging = Import-UtilityPSLogging

$PSLogging.GetConfiguration("Delimeter")
$PSLogging.Message('test')
$PSLogging.UtilityReloadConfiguration('Delimeter')
$PSLogging.Message('test')


$Test = [PSLogger]::new()

$Test.UtilityTestFilePath("./")
$Test.UtilityReloadConfiguration(@("Delimeter"))
$Test.GetConfiguration("Delimeter")
$Test.Message("This is a new message")


Function Import-UtilityPSLogging{
    $PSLogger = [PSLogger]::new()
    $PSLogger
}
Export-ModuleMember -Function @('Greeting')

ScriptsToProcess = @(
    './Public/Functions.ps1'
)

