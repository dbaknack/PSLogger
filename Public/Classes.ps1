$ErrorActionPreference = 'stop'
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
    $Configuration = $this.GetConfiguration(@{Reload = $true})
    $TrackedValues = $this.GetTrackedValues(@{Reload = $true})

    # first validate that the configurations looks like what we expect it to look like
    [psobject]ValidateConfiguration([hashtable]$fromSender){
        Write-Verbose -Message "[ValidateConfiguration]::running configuration validation..." -Verbose
        $allowedPropertiesList = $this.LogFormatTable.Properties
        $RESULTS_TABLE  =   @{
            isSuccessfull   =   [bool]
            details         =   [psobject]
        }
        foreach($property in $fromSender.keys){
            if($allowedPropertiesList -notcontains $property){
                $RESULTS_TABLE.isSuccessfull = $false
                $RESULTS_TABLE.details = "not all the properties in your configuration file are allowed"
            }else{
                $RESULTS_TABLE.isSuccessfull = $true
            }
        }
        return $RESULTS_TABLE
    }
    
    # method to set the configuration
    [void]SetConfiguration([hashtable]$fromSender){
        Write-Verbose -Message "[SetConfiguration]::setting the configuration from disk to the class parameter..." -Verbose
        $this.Configuration = $fromSender
    }

    # method to set the tracked values
    [void]SetTrackedValues([hashtable]$fromSender){
        Write-Verbose -Message "[SetConfiguration]::setting the tracked values from disk to the class parameter..." -Verbose
        $this.TrackedValues = $fromSender
    }

    # the configuration file gets read into memory
    [psobject]LoadConfiguration(){
        Write-Verbose -Message "[LoadConfiguration]::reading configuration from disk..." -Verbose
        $RESULTS_TABLE  =   @{
            isSuccessfull   =   [bool]
            details         =   [psobject]
        }
        $preLoadedConfiguration = ((Get-Content $this.ConfigFilePath) | ConvertFrom-Json -AsHashtable)
        $RESULTS_TABLE = ($this.ValidateConfiguration($preLoadedConfiguration))
       
        if( -not ($RESULTS_TABLE.isSuccessfull)){
            Write-Error -Message $RESULTS_TABLE.details -Category "InvalidData"
        }

        # the configuration is set if its valid
        $this.SetConfiguration($preLoadedConfiguration)
        return $RESULTS_TABLE
    }

    [void]LoadTrackedValues(){
        Write-Verbose -Message "[LoadTrackedValues]::reading tracked values from disk..." -Verbose
        $props = $this.GetConfiguration(@{Reload = $true})
        
        $preLoadedTrackedValues = (Get-Content $props.TrackedValuesFile) | ConvertFrom-Json -AsHashtable
       
        # the tracked is set
        $this.SetTrackedValues($preLoadedTrackedValues)
    }

    # get the configuration, at this point its in memory, LoadConfiguration to get new changes
    [psobject]GetConfiguration([hashtable]$fromSender){
        # if reload is true, the configuration is read from disk
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

    [psobject]RetentionPolicy(){
        $props = $this.GetConfiguration(@{Reload = $true})
        $logFileList = (Get-ChildItem -Path  $props.LogFilePath -Filter "*$($props.LogFileName)") 

        $retentionList = $logFileList | Sort-Object -Property  LastWriteTime -Descending | Select-Object -First ($props.Retention.mostrecent -1)
        $canCreateNewFile = $true
        $mostRecentLog =  ($this.GetCurrentLogFile()).mostRecentLog
        write-host $mostRecentLog -f Blue
        [string]$myInterval = $props.Interval.keys
        [string]$myIntervalValue = $props.Interval.values

        $DateTimeCommandString= ('(Get-Date).Add{0}(-{1})' -f ($myInterval),($myIntervalValue))
        $scriptBlock = [scriptblock]::Create($DateTimeCommandString)
        $DateTimeOffset = Invoke-Command -ScriptBlock $scriptBlock

        # the second the most recent file is older than than $DateTimeOffset the policy is checked
        if(($mostRecentLog.CreationTime) -lt $DateTimeOffset){
            Write-Host "Most recent log has a creationg time of  $(($mostRecentLog.CreationTime).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor red
            Write-host "The datetime offset is $(($DateTimeOffset).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor red
            $logFileList | Select-Object -Property * | Where-Object {$retentionList.Name -notcontains $_.Name} | Remove-Item
            
       }else{
            Write-Host "Most recent log has a creationg time of  $(($mostRecentLog.CreationTime).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
            Write-host "The datetime offset is $(($DateTimeOffset).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
            $canCreateNewFile = $false
       }
       return $canCreateNewFile
    }

    [psobject]GetCurrentLogFile(){
        # reloading configuration
        $props = $this.GetConfiguration(@{Reload = $true})
        $logFileList = (Get-ChildItem -Path  $props.LogFilePath -Filter "*$($props.LogFileName)")
        if($null -eq $logFileList){
            write-verbose -Message "[GetCurrentLogFile]:: there is no current log file in the given location" -Verbose
            $mostRecentLog = @{
                isNull = $true
            }
        }else{
            $mostRecentLog = @{
                isNull = $false
                mostRecentLog = $logFileList | Sort-Object -Property  LastWriteTime -Descending | Select-Object -First 1
            }
        }
        return $mostRecentLog
    }

    [psobject]CreateLogFile(){
        $props = $this.GetConfiguration(@{Reload = $true})
        $reference = $this.GetTrackedValues(@{Reload = $true}) 
        $canCreateNewFile = [bool]
        # if there is no log file(s), we can reset the logfileid
        if(($this.GetCurrentLogFile()).isNull){
            Write-Verbose -Message "[GetConfiguration]:: reseeding the tracked value properties" -Verbose
            $reference = $this.GetTrackedValues(@{Reload = $true})    
            $reference.LogFileID = $props.LogIdentity[0]
            $reference.LastDelimeter = $props.Delimeter
            $reset_TrackedValues = $reference | ConvertTo-Json
            Set-Content -Path $props.TrackedValuesFile -Value $reset_TrackedValues
        }else{
            Write-Verbose -Message "[GetConfiguration]:: using the current tracked value properties" -Verbose
            $canCreateNewFile = $this.RetentionPolicy()
        }
        
        $preFileName = "{0}_$(($props.LogFileName))"
        $posFileName = [string]
        $finalName = [string]

        $lastFileID = ($this.GetTrackedValues(@{Reload = $true})).LogFileID
        
        # when logs arent being cycles, then just write to the same file
        if($props.CycleLogs -eq "false"){
            $posFileName = $preFileName -f $lastFileID
            $finalName = "$($props.LogFilePath)/$($posFileName)"

            if(-not (Test-Path -Path $finalName)){
                New-Item -Path $finalName -ItemType "File"
            }else{
                Write-host "log file $($finalName) already exists"
            }
        }else{
            $currentFileID = $lastFileID + $props.LogIdentity[1]
            $posFileName = $preFileName -f $currentFileID
            $finalName = "$($props.LogFilePath)/$($posFileName)"

            if(-not (Test-Path -Path $finalName)){
                if($canCreateNewFile){
                    New-Item -Path $finalName -ItemType "File"
                    $reference.LogFileID = $currentFileID
                    $reference = $reference | ConvertTo-Json
                    Set-Content -Path $props.TrackedValuesFile -Value $reference
                }
                else{
                    Write-Verbose -Message "[CreateLogFile]:: can't create a new log file, the most recent log file is still within the retention period" -Verbose
                }
            }else{
                Write-host "log file $($finalName) already exists"

            }
        }
        return $reference
    }

    [psobject]GetHeadingProperties($logThis){
        $props = $this.GetConfiguration(@{Reload = $true})
        
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

    [psobject]GetSeedProperties(){
        $props = $this.GetConfiguration(@{Reload = $true})
        $SeedPropertiesTable = [ordered]@{
            Seedof = $props.EntryIdentity[0]
            Incrementof = $props.EntryIdentity[1]
        }
        return $SeedPropertiesTable
    }

    [psobject]GetLastLogEntry(){
        $LogFilePath = ($this.GetCurrentLogFile()).mostRecentLog
        return Get-Content -Tail 1 -Path $LogFilePath
    }

    [void]LogThis([string]$logThis){
        $props = $this.GetTrackedValues(@{Reaload = $true})
        $config_props = $this.GetConfiguration(@{Reload = $true})
        write-host "the last delimeter: $($props.LastDelimeter)" -ForegroundColor cyan
        $SeedProps = $this.GetSeedProperties()
        $Delimenter = $config_props.Delimeter
        $this.CreateLogFile()
        $LogFilePath = ($this.GetCurrentLogFile()).mostRecentLog
        $lastEntryID = [int]

        # get the last log entry
        $lastLine = $this.GetLastLogEntry()
       # return $LastDelimeter
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
$test.LogThis("logthis")
