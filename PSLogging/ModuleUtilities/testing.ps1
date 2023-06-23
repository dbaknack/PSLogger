Import-Module "./PSLogging"
$PSLogging = Import-UtilityPSLogging
$PSLogging.Message('test')
$PSLogging.UtilityReloadConfiguration('Delimeter')
$PSLogging.Message('test')