Import-Module "./PSLogger"
$PSLogging = Import-UtilityPSLogging
Get-Module


UtilityReloadConfiguration
Import-UtilityPSLogging

Update-UDFConfiguration -Setting 'Delimeter' -Value '|'
Remove-Module PSLogging
$cntr = 0
do{
    $messag = get-date
    $PSLogging.Message($messag)
    Start-Sleep -Milliseconds 50
    $cntr++
}until($cntr -ge 1000)
Get-Variable "TestSessionTable"
get-variable -name "testscope"
$testscope = 't'


# can we list the modules, make sure that theyre corretly imported
Get-Module


# the class utilities
$PSLogging.UtilityTestFilePath("./")
$PSLogging.UtilityReloadConfiguration(@("Delimeter"))
$PSLogging.GetConfiguration("SeedValue")
$PSLogging.Message("This is a new message")




$Test.LoadConfiguration()
$test.GetTrackedValues(@{Reload = $true})
# when reload = $true then its read from disk
$test.GetConfiguration(@{Reload = $true}).Interval

# when reload = $false then its read from memory
$test.GetConfiguration(@{Reload = $false})

$test.CreateLogFile()
$test.RetentionPolicy()
$test.GetCurrentLogFile()


$test.TrackedValues
