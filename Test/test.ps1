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





$Test.LoadConfiguration()
$test.GetTrackedValues(@{Reload = $true})
$test.GetConfiguration(@{Reload = $true})
$test.GetConfiguration(@{Reload = $false})

$test.CreateLogFile()
<#
when creating a fil
#>
$test.RetentionPolicy()
$test.GetCurrentLogFile()


$test.TrackedValues
