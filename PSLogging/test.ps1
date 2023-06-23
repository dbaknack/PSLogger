Import-Module "./PSLogging"
$PSLogging = Import-UtilityPSLogging
Get-Module

Update-PSLoggingConfig -Setting 'Delimeter' -Value 'r'
Remove-Module PSLogging*
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