$ErrorActionPreference = 'Stop'
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
$VerbosePreference = 'Continue'  # Turn on verbose output
$VerbosePreference = 'SilentlyContinue'  # Turn off verbose output

class PSLogger{
    $LogFormatTable = @{
        Properties = @(
            "Headings",
            "EntryIdentity",
            "LogIdentity",
            "DateTimeFormat",
            "Delimeter",
            "OutputColor",
            "CycleLogs",
            "Interval",
            "Retention",
            "LogFilePath",
            "LastDelimeterPath",
            "LogFileName",
            "TrackedValuesFile",
            "EnableLogging"
        )
        Headings = @(
            "UserName",
            "DateTime",
            "HostName",
            "Message"
        )
    }
    $ConfigFilePath = [string]"./Private/Configuration.json"
    $Configuration  = $this.GetConfiguration(@{Reload = $true})
    $TrackedValues  = $this.GetTrackedValues(@{Reload = $true})

    [psobject]ValidateConfiguration([hashtable]$fromSender){
        Write-Verbose -Message "[ValidateConfiguration]::running configuration validation..." -Verbose
        $allowedPropertiesList = $this.LogFormatTable.Properties
        $RESULTS_TABLE  =   @{
            isSuccessfull   =   [bool]
            Data            =   [psobject]
        }
        $propertiesList = $fromSender.keys
        foreach($property in ($propertiesList)){
            if($allowedPropertiesList -notcontains $property){
                $RESULTS_TABLE.isSuccessfull = $false
            }else{
                $RESULTS_TABLE.isSuccessfull = $true
            }
        }
        if($RESULTS_TABLE.isSuccessfull -eq $false){
            Write-Error -Message "[ValidateConfiguration]:: not all the properties in your configuration file are allowed" -Category "InvalidData" 
        }
        $RESULTS_TABLE.Data = $propertiesList
        return $RESULTS_TABLE
    }

    [void]SetConfiguration([hashtable]$fromSender){
        Write-Verbose -Message "[SetConfiguration]::setting the configuration from disk to the class parameter...`n" -Verbose
        $this.Configuration = $fromSender
    }

    [void]SetTrackedValues([hashtable]$fromSender){
        Write-Verbose -Message "[SetConfiguration]::setting the tracked values from disk to the class parameter..." -Verbose
        $this.TrackedValues = $fromSender
    }

    [psobject]LoadConfiguration(){
        Write-Verbose -Message "[LoadConfiguration]::reading configuration from disk..." -Verbose
        $RESULTS_TABLE  =   @{
            isSuccessfull   =   [bool]
            Data            =   [psobject]
        }
        $preLoadedConfiguration = ((Get-Content $this.ConfigFilePath) | ConvertFrom-Json -AsHashtable)
        $RESULTS_TABLE = ($this.ValidateConfiguration($preLoadedConfiguration))
       
        $this.SetConfiguration($preLoadedConfiguration)
        return $RESULTS_TABLE
    }

    [void]LoadTrackedValues(){
        Write-Verbose -Message "[LoadTrackedValues]::reading tracked values from disk..." -Verbose
        $props = $this.GetConfiguration(@{Reload = $false})
        
        $preLoadedTrackedValues = (Get-Content $props.TrackedValuesFile) | ConvertFrom-Json -AsHashtable
       
        $this.SetTrackedValues($preLoadedTrackedValues)
    }

    [psobject]GetConfiguration([hashtable]$fromSender){
        switch($fromSender.Reload){
            $true {
                Write-Verbose -Message "[GetConfiguration]::loading configuration from disk..." -Verbose
                $this.LoadConfiguration()
            }
            default {
                Write-Verbose -Message "[GetConfiguration]::getting configuration from class parameter(s)..." -Verbose
            }
        }
        return $this.Configuration
    }

    [psobject]GetTrackedValues([hashtable]$fromSender){
        switch($fromSender.Reload){
            $true {
                Write-Verbose -Message "[GetTrackedValues]::loading tracked values from disk..." -Verbose
                $this.LoadTrackedValues()
            }
            default{
                Write-Verbose -Message "[GetTrackedValues]::getting tracked values from class parameter(s)..." -Verbose
            }
        }
        return $this.TrackedValues
    }

    [psobject]RetentionPolicy([hashtable]$fromSender){
        Write-Verbose -Message "-+ [RetentionPolicy]" -Verbose
        $RESULTS_TABLE  =   @{
            isSuccessfull   = [bool]
            Data            = @{}
        }

        $RESULTS_TABLE.Data.Add("CanCreateNewFile",$true)
        if($fromSender.Reload){
            Write-Verbose -Message "--+ Reloading configuration" -Verbose
        }else{
            Write-Verbose -Message "--+ Not realoding configuration" -Verbose
        }
        $config         = $this.GetConfiguration($fromSender)
        $logFileList    = (Get-ChildItem -Path  $config.LogFilePath -Filter "*$($config.LogFileName)") 
        $retentionList  = $logFileList | Sort-Object -Property  "LastWriteTime" -Descending | Select-Object -First ($config.Retention.mostrecent -1)

        $mostRecentLog              =   ($this.GetCurrentLogFile(@{Reload = $false}))
        [string]$myInterval         =   $config.Interval.keys
        [string]$myIntervalValue    =   $config.Interval.values

        $DateTimeCommandString  = ('(Get-Date).Add{0}(-{1})' -f ($myInterval),($myIntervalValue))
        $scriptBlock            = [scriptblock]::Create($DateTimeCommandString)
        $DateTimeOffset         = Invoke-Command -ScriptBlock $scriptBlock

        if(($mostRecentLog.Data.CreationTime) -lt $DateTimeOffset){
            Write-Verbose -Message "--+ Per the retention policy, purging some files..." -Verbose
            $logFileList | Select-Object -Property * | Where-Object {$retentionList.Name -notcontains $_.Name} | Remove-Item
            
       }else{
            Write-Verbose -Message "[RetentionPolicy]:: per the retention policy, no new files can be created..." -Verbose
            $RESULTS_TABLE.Data.GetConfiguration = $false
       }
       return $RESULTS_TABLE
    }

    [psobject]GetCurrentLogFile($fromSender){
        Write-Verbose -Message "-+ [GetCurrentLogFile]" -Verbose
        $RESULTS_TABLE  =   @{
            isSuccessfull   = [bool]
            Data            = [psobject]
        }

        if($fromSender.Reload){
            Write-Verbose -Message "--+ Reloading configuration" -Verbose
        }else{
            Write-Verbose -Message "--+ Not Realoading configuration" -Verbose
        }

        $config = $this.GetConfiguration($fromSender)
        if( -not (Test-Path -Path "$($config.LogFilePath)")){
            Write-Error -Message "The path in your configuration file '$($config.LogFilePath)' is not reachable"
        }else{
            Write-Verbose -Message "--+ The path in your configuration file '$($config.LogFilePath)' is valid" -Verbose
        }

        $logFileList = (Get-ChildItem -Path  $config.LogFilePath -Filter "*$($config.LogFileName)")
        if($null -eq $logFileList){
            Write-Verbose -Message "--+ The log file location is empty" -Verbose
            $RESULTS_TABLE.isSuccessfull = $true
            $RESULTS_TABLE.Data = @{
                isNull          = $true
                mostRecentLog   = $null
            }
        }else{
            Write-Verbose -Message "--+ The log file location has '$($logFileList.count)' log files" -Verbose
            $RESULTS_TABLE.isSuccessfull = $true
            $RESULTS_TABLE.Data = @{
                isNull          = $false
                mostRecentLog   = $logFileList | Sort-Object -Property  LastWriteTime -Descending | Select-Object -First 1
            }
        }
        return $RESULTS_TABLE
    }

    [psobject]CreateLogFile([hashtable]$fromSender){
        Write-Verbose -Message "-+ [CreateLogFile]" -Verbose

        $config     = $this.GetConfiguration($fromSender)
        $trackedVal = $this.GetTrackedValues($fromSender)
        $canCreateNewFile = $true

        if(($this.GetCurrentLogFile($fromSender)).Data.isNull){
            Write-Verbose -Message "--+ No current log file present in $($config.LogFilePath), resettings LogFileID" -Verbose
            $resetTrackedValues = [ordered]@{
                LogFileID       = $config.LogIdentity[0]
                LastDelimeter   = $config.Delimeter
            }
            $resetTrackedValues = $resetTrackedValues  | ConvertTo-Json
            Set-Content -Path $config.TrackedValuesFile -Value $resetTrackedValues
        }else{
            Write-Verbose -Message "--+ Checking the retention values" -Verbose
            $canCreateNewFile = $this.RetentionPolicy(@{Reload = $true}).Data.CanCreateNewFile
        }
        
        $preFileName = "{0}_$(($config.LogFileName))"
        $posFileName = [string]
        $finalName = [string]

        $lastFileID = ($this.GetTrackedValues(@{Reload = $false})).LogFileID

        if($config.CycleLogs -eq "false"){
            $posFileName = $preFileName -f $lastFileID
            $finalName = "$($config.LogFilePath)/$($posFileName)"

            if(-not (Test-Path -Path $finalName)){
                New-Item -Path $finalName -ItemType "File"
            }else{
                Write-host "log file $($finalName) already exists"
            }
        }else{
            $currentFileID = $lastFileID + $config.LogIdentity[1]
            $posFileName = $preFileName -f $currentFileID
            $finalName = "$($config.LogFilePath)/$($posFileName)"

            if(-not (Test-Path -Path $finalName)){
                if($canCreateNewFile){
                    New-Item -Path $finalName -ItemType "File"
                    $trackedVal.LogFileID = $currentFileID
                    $trackedVal = $trackedVal | ConvertTo-Json
                    Set-Content -Path $config.TrackedValuesFile -Value $trackedVal
                }
                else{
                    Write-Verbose -Message "--+ Can't create a new log file, the most recent log file is still within the retention period" -Verbose
                }
            }else{
                Write-Verbose -Message "--+ file already exists" -Verbose

            }
        }
        return $true
    }

    [psobject]GetHeadingProperties($logThis){
        $props = $this.GetConfiguration(@{Reload = $false})
        
        $LogMessageList = @()
        $LogMessageOptionsTable = [ordered]@{
            UserName    =  (EvaluateOS).OS_USER
            DateTime    = (Get-Date).ToString($Props.DateTimeFormat)
            Message     = $logThis
            HostName    = (EvaluateOS).OS_HOST
        }
        foreach($heading in $props.Headings){
           $LogMessageList += $LogMessageOptionsTable[$heading]
        }
        return $LogMessageList
    }

    [psobject]GetSeedProperties([hashtable]$fromSender){
        Write-Verbose -Message "-+ [GetSeedProperties]" -Verbose
        $RESULTS_TABLE  =   @{
            isSuccessfull   =   [bool]
            Data            =   [psobject]
        }

        if($fromSender.Reload){
            Write-Verbose -Message "--+ Reload configuration: 'true'" -Verbose
        }else{
            Write-Verbose -Message "--+ Reload configuration: 'false'" -Verbose
        }
        $config = $this.GetConfiguration($fromSender)
        $RESULTS_TABLE.Data = [ordered]@{
            Seedof      = $config.EntryIdentity[0]
            Incrementof = $config.EntryIdentity[1]
        }
        return $RESULTS_TABLE
    }

    [psobject]GetLastLogEntry(){
        # GetCurrentLogFile (->)
        $LogFilePath = ($this.GetCurrentLogFile()).mostRecentLog
        return Get-Content -Tail 1 -Path $LogFilePath
    }

    [void]LogThis([string]$logThis){
        $props          = $this.GetTrackedValues(@{Reaload = $true})
        $config_props   = $this.GetConfiguration(@{Reload = $true})
        $Delimenter     = $config_props.Delimeter

        Write-Verbose -Message "-+ [LogThis]" -Verbose
        Write-Verbose -Message "--+ LastDelimeter: '$($props.LastDelimeter)'" -Verbose
        Write-Verbose -Message "--+ LogFileID: '$($props.LogFileID)'`n" -Verbose
        
        $SeedProps  = $this.GetSeedProperties(@{Reload = $false})
        
        Write-Verbose -Message "-+ [LogThis]" -Verbose
        $this.CreateLogFile(@{Reload = $false})
        $LogFilePath = ($this.GetCurrentLogFile()).mostRecentLog
        $lastEntryID = [int]

        $lastLine = $this.GetLastLogEntry()
        if($lastline){
            Write-Host "there was a last log entry"
            $lastEntryID = [int]($lastLine.Split($props.LastDelimeter))[0]
        }else{
            Write-Host "Log is currently empty"
            $lastEntryID = [int]($SeedProps["Seedof"])
        }

        $lastEntryID = $lastEntryID + $SeedProps["Incrementof"]
        $myLogEntry = @()
        $myLogEntry += $lastEntryID

        $myLogEntry += $this.GetHeadingProperties($logThis)

        $myLogEntry = $myLogEntry -join $Delimenter
        write-host "logging message" -ForegroundColor cyan

        Add-Content -Path $LogFilePath -Value $myLogEntry

        write-host "saving the current delimenter to be used as last delimenter on next run $Delimenter" -ForegroundColor cyan
        $props.LastDelimeter = $Delimenter
        $props = $props | ConvertTo-Json
        Set-Content -Path $config_props.TrackedValuesFile -value $props
    }
}

$test= [PSLogger]::new()
$test.GetCurrentLogFile(@{Reload = $true})
$test.GetCurrentLogFile(@{Reload = $false})



$test.GetTrackedValues(@{Reaload = $false})

# when 
$test.CreateLogFile(@{Reload = $true})
$test.CreateLogFile(@{Reload = $false})

$test.RetentionPolicy(@{Reload = $true})
$test.RetentionPolicy(@{Reload = $false}).data.CanCreateNewFile

$test.ValidateConfiguration(
    $test.GetConfiguration(@{Reload = $true})
)

$test.ValidateConfiguration(
    $test.GetConfiguration(@{Reload = $false})
)

$test.LoadConfiguration()
$test.LoadTrackedValues()
$test.Configuration
$test.LogThis("this is something i want to track with a log entry")
$test.GetSeedProperties($test.GetConfiguration(@{Reload = $true}))


(Get-ChildItem -Path ./Test/Logs).count

$test.GetTrackedValues(@{Reload = $true})

$test.GetTrackedValues(@{Reload = $false})

# when reload = $true then its read from disk

$test.GetConfiguration(@{Reload = $false})

$test.CreateLogFile(@{Reload = $false})


$test.GetCurrentLogFile()