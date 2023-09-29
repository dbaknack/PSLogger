class PSLogger{
    $LogFormatTable = @{
        Properties = @(
            "Headings",
            "Identity",
            "DateTimeFormat",
            "Delimeter",
            "OutputColor",
            "LogFilePath",
            "LastDelimeterPath",
            "LogFileName",
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
        $allowedPropertiesList = $this.LogFormatTable.Properties
        foreach($property in $fromSender.keys){
            if($allowedPropertiesList -notcontains $property){
                Write-Verbose -Message "$property is now allowed" -Verbose
            }else{
                Write-Verbose -Message "$property is allowed" -Verbose
            }
        }
        return $true
    }

    # method to set the configuration
    [void]SetConfiguration([hashtable]$fromSender){
        $this.Configuration = $fromSender
    }
    [void]SetTrackedValues([hashtable]$fromSender){
        $this.TrackedValues = $fromSender
    }

    # the configuration file get read into memory here, validation will take place here
    [void]LoadConfiguration(){
       $preLoadedConfiguration = ((Get-Content $this.ConfigFilePath) | ConvertFrom-Json -AsHashtable)
       $this.ValidateConfiguration($preLoadedConfiguration)

       # the configuration is set if its valid
       $this.SetConfiguration($preLoadedConfiguration)
    }
    [void]LoadTrackedValues(){
        $trackedValuesFile = ($this.Configuration.TrackedValuesFile)
        $preLoadedValues = ((Get-Content $trackedValuesFile) | ConvertFrom-Json -AsHashtable)
        $this.SetTrackedValues($preLoadedValues)
    }

    # get the configuration, at this point its in memory, LoadConfiguration to get new changes
    [psobject]GetConfiguration([hashtable]$fromSender){
        switch($fromSender.Reload){
            $true {
                $this.LoadConfiguration()
            }
        }
        return $this.Configuration
    }
    [psobject]GetTrackedValues([hashtable]$fromSender){
        switch($fromSender.Reload){
            $true {
                $this.LoadTrackedValues()
            }
        }
        return $this.TrackedValues
    }

    [void]RetentionPolicy(){
        $props = $this.GetConfiguration(@{Reload = $true})
       
        $logFileList = (Get-ChildItem -Path  $props.LogFilePath -Filter "*$($props.LogFileName)") | Sort-Object -Property CreationTime
        $retainloglist = $logFileList | Select-Object -First $props.Retention.mostrecent
       (Compare-Object -ReferenceObject $retainloglist -DifferenceObject $logFileList).InputObject | 
       Remove-Item 
    }
    [psobject]CreateLogFile(){
        # recheck properties from disk when creating a log file
        $this.RetentionPolicy()
        $props = $this.GetConfiguration(@{Reload = $true})
        $timeInterval = $props.Interval.keys
        $intervalValue = $props.Interval.values
        $preFileName = "{0}_$(($props.LogFileName))"
        $posFileName = [string]
        $finalName = [string]
        $lastFileID = ($this.GetTrackedValues(@{Reload = $true})).LogFileID
        $reference = $this.GetTrackedValues(@{Reload = $false})
       write-host " are logs being cycled : $($props.CycleLogs)"
        # when logs arent being cycles, then just write to the same file
        if($props.CycleLogs -eq "false"){
            $posFileName = $preFileName -f $lastFileID
            $finalName = "$($props.LogFilePath)/$($posFileName)"
            write-host $finalName
            if(-not (Test-Path -Path $finalName)){
                New-Item -Path $finalName -ItemType "File"
            }else{
                Write-host "log file $($finalName) already exists"
            }
        }else{
            $currentFileID = $lastFileID + $props.LogIdentity[1]
            Write-Host "the current fileid is $currentfileID"
            write-host "the prefilename is $preFileName"
            $posFileName = $preFileName -f $currentFileID
            write-host "the post filename is $posfilename"
            $finalName = "$($props.LogFilePath)/$($posFileName)"
            write-host "the final path is $finalName"

            if(-not (Test-Path -Path $finalName)){
                New-Item -Path $finalName -ItemType "File"
                $reference.LogFileID = $currentFileID
                $reference = $reference | ConvertTo-Json
                Set-Content -Path $props.TrackedValuesFile -Value $reference
                # already reloaded in this work flow, no need to reload

            }else{
                Write-host "log file $($finalName) already exists"

            }
        }
        return $reference
    }
    [psobject]UtilityTestFilePath([string]$FilePath){
        if(-not(Test-Path $FilePath)){
            return $false
        }
       Write-Verbose -Message 'passed test' -Verbose
        return $true
    }

    [psobject]GetHeadingProperties($logThis){
        $headings = $($this.Configuration.LoggingFormat.Headings).split(" ")
        $LogMessageList = @()
        $LogMessageOptionsTable = [ordered]@{
            UserName    =  $env:USER
            DateTime    = (Get-Date).ToString($this.Configuration.LoggingFormat.DateTimeFormat)
            Message     = $logThis
            HostName    = "ComputerName"
        }
        foreach($heading in $headings){
           $LogMessageList += $LogMessageOptionsTable[$heading]
        }
        return $LogMessageList
    }

    [psobject]GetSeedProperties(){
        $properties = ($this.Configuration.LoggingFormat.SeedValue).Split(" ")
        $SeedPropertiesTable = [ordered]@{
            Seedof = $properties[0]
            Incrementof = $properties[1]
        }
        return $SeedPropertiesTable
    }

    [psobject]GetLastLogEntry(){
        $LogFilePath = $this.Configuration.Logs.LogFilePath
        return Get-Content -Tail 1 -Path $LogFilePath
    }

    [void]SetLastDelimeter(){
        $this.Configuration.LastDelimeter = $this.GetLastDelimeter()
    }

    [psobject]GetLastDelimeter(){
        $DelimeterTable = (Get-Content -Path $this.LastDelimeterPath | ConvertFrom-Json -AsHashtable)
        return $DelimeterTable.LastDelimeter
    }

    [void]SaveLastDelimimeter(){
        $outputDelimenter = @{
            LastDelimeter = $this.GetConfiguration("Delimeter")
        }
        $outputDelimenter = $outputDelimenter | ConvertTo-Json
        Set-Content -Path $this.LastDelimeterPath -Value $outputDelimenter
    }



    [void]UtilityReloadConfiguration([array]$Reload){
        $propertyTable = @{
            parentprops = [array]($this.Configuration.keys)
        }
        foreach($property in $propertyTable.parentprops){
            if($this.Configuration.$property.keys -contains $Reload){
                $Message = '{0} {1}' -f '+-',"Parent property: '$property'"
                Write-Verbose $Message -Verbose
                $NewValue = $this.GetConfiguration($Reload)
                $this.Configuration.$property[$Reload[0]] = $NewValue
            }
        }
    }

    [psobject]GetConfiguration_old([string]$Property){
        $Message = "+-- {0} '{1}'" -f "Getting '$($Property)' set value from",$this.ConfigFilePath
        Write-Verbose $Message -Verbose

        $ConfiguredProperties = Get-Content $this.ConfigFilePath | Convertfrom-Json
        $PropertyObject = ($ConfiguredProperties | Select-Object $Property).$Property

        if(-not($PropertyObject)){
            $Message = "- {0} {1}" -f "The property provied $($Property)", "doesnt exists..."
            Write-Verbose $Message -Verbose
            return $false
        }
        $Message = "+-- {0} {1}" -f $Property,"value set..`n"
        Write-Verbose $Message -Verbose
        $this.Configuration.ConsoleView
        return [string]$PropertyObject
    }

    [void]LogThis([string]$logThis){
        $LastDelimeter = $this.GetLastDelimeter()
        write-host "the last delimeter: $LastDelimeter" -ForegroundColor cyan
        $SeedProps = $this.GetSeedProperties()
        $Delimenter = $this.Configuration.LoggingFormat.Delimeter
        $EnableLogging = $this.Configuration.Logs.EnableLogging
        $LogFilePath = $this.Configuration.Logs.LogFilePath
        $lastEntryID = [int]

        # check if logging is enabled
        if($EnableLogging -eq 'true'){
            if(-not($this.UtilityTestFilePath($LogFilePath))){
                $Message = '{0}' -f "Invalid File Path: $LogFilePath"
                Write-Verbose -Message $Message -Verbose
            }
        }
    
        # get the last log entry
        $lastLine = $this.GetLastLogEntry()
       # return $LastDelimeter
        if($lastline){
            Write-Host "there was a last log entry"
            $lastEntryID = [int]($lastLine.Split($LastDelimeter)[0])
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
       # return $MessageEntryTable
        Add-Content -Path $LogFilePath -Value $myLogEntry
       # return $myLogEntry
       write-host "saving the current delimenter to be used as last delimenter on next run $Delimenter" -ForegroundColor cyan
        $this.SaveLastDelimimeter()
    }
}
$test= [PSLogger]::new()
$test.GetTrackedValues(@{Reload = $true})
# when reload = $true then its read from disk
$test.GetConfiguration(@{Reload = $true}).Interval

# when reload = $false then its read from memory
$test.GetConfiguration(@{Reload = $false})

$test.CreateLogFile()
$test.RetentionPolicy()