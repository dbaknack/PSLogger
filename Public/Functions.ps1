Function Greeting {
    $text = ' 
    /$$$$$$$   /$$$$$$  /$$        /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$ /$$   /$$  /$$$$$$ 
    | $$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$|_  $$_/| $$$ | $$ /$$__  $$
    | $$  \ $$| $$  \__/| $$      | $$  \ $$| $$  \__/| $$  \__/  | $$  | $$$$| $$| $$  \__/
    | $$$$$$$/|  $$$$$$ | $$      | $$  | $$| $$ /$$$$| $$ /$$$$  | $$  | $$ $$ $$| $$ /$$$$
    | $$____/  \____  $$| $$      | $$  | $$| $$|_  $$| $$|_  $$  | $$  | $$  $$$$| $$|_  $$
    | $$       /$$  \ $$| $$      | $$  | $$| $$  \ $$| $$  \ $$  | $$  | $$\  $$$| $$  \ $$
    | $$      |  $$$$$$/| $$$$$$$$|  $$$$$$/|  $$$$$$/|  $$$$$$/ /$$$$$$| $$ \  $$|  $$$$$$/
    |__/       \______/ |________/ \______/  \______/  \______/ |______/|__/  \__/ \______/ 
    '
    Write-Host $text
}
Function EvaluateOS{
    if($IsWindows){
        $OS_PARAMETERS = @{
            OS_HOST = $env:COMPUTERNAME
            OS_USER = $env:USERDOMAIN
        }
    }
    if($IsMacOS){
        $OS_PARAMETERS = @{
            OS_HOST = "MAC_OS"
            OS_USER = "MAC_USER"
        }
    }
    $OS_PARAMETERS
}
Function PSLogger([switch]$InitializeLog){
    if($InitializeLog){
        $PSLogger = [PSLogger]::new()
        $PSLogger 
    }
}