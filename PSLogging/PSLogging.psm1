Import-Module "./ModuleUtilities/PSLoggingFunctions.psm1"
class PSLogging{
    $ConfigFilePath = [string]"./ModuleConfig/PSLoggingConfig.json"
    $Configuration = @{
        LoggingFormat = @{
            Headings        = [array]$this.GetConfiguration('Headings')
            SeedValue       = [array]$this.GetConfiguration('SeedValue')
            DateTimeFormat  = $this.GetConfiguration('DateTimeFormat')
            Delimeter       = $this.GetConfiguration('Delimeter')
        }
        Logs = @{
            LogFilePath = [string]$this.GetConfiguration('LogFilePath')
            EnableLogging = [bool]$this.GetConfiguration('EnableLogging')
        }
        ConsoleView = @{
            OutputColor = $this.GetConfiguration('OutputColor')
        }
    }
    [psobject]UtilityTestFilePath([string]$FilePath){
        if(-not(Test-Path $FilePath)){
            return $false
        }
       Write-Verbose -Message 'passed test' -Verbose
        return $true
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
    [psobject]GetConfiguration([string]$Property){
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
    [void]Message([string]$LogEntry){
        $EnableLogging = $this.Configuration.Logs.EnableLogging
        $LogFilePath = $this.Configuration.Logs.LogFilePath
        if($EnableLogging -eq 'true'){
            if(-not($this.UtilityTestFilePath($LogFilePath))){
                $Message = '{0}' -f "Invalid File Path: $LogFilePath"
                Write-Verbose -Message $Message -Verbose
                #return $false
            }
        }
        $HeadingsString = $this.Configuration.LoggingFormat.Headings
        $HeadingsTable = @{
            HeadingsList = $HeadingsString.split(' ')
            HeadingsOffset = ($HeadingsString.split(' ')).count -1
            IndexList = $null
        }
        foreach($index in (0..$HeadingsTable.HeadingsOffset)){
           [array]$HeadingsTable.IndexList += "{$index}" 
        }
        $SeedVaule = $this.Configuration.LoggingFormat.SeedValue
        $SeedValueList = $SeedVaule.split(' ')
        $SeedProps = @{
            Seedof = $SeedValueList[0]
            Incrementof = $SeedValueList[1]
        }
        $DatetimeFormat = $this.Configuration.LoggingFormat.DateTimeFormat
        $LogpropTable = @{
           SeedProperties = $SeedProps
        }

        $MessageFormat = @{
               String =  $HeadingsTable.IndexList -join "$($this.Configuration.LoggingFormat.Delimeter)"
        }
        $MessageEntryTable = @{
            LogFilePath = $LogFilePath
            String = $MessageFormat.String
        }
        if(Get-Content -Tail 1 -Path $LogFilePath){
           $lastline = (Get-Content -Tail 1 -Path $LogFilePath) 
           $currentrow = [int]($lastline.Split("$($this.Configuration.LoggingFormat.Delimeter)")[0]).Replace("'","")
        }else{
            $currentrow = [int]$LogpropTable.SeedProperties.Seedof
        }
        $currentrow =  $currentrow + $LogpropTable.SeedProperties.Incrementof
        $tobelogged = $MessageEntryTable.string -f $currentrow,(get-date).ToString($DatetimeFormat),$LogEntry,'computername'
        Add-Content -Path $LogFilePath -Value $tobelogged
    }
}

Function Import-UtilityPSLogging{
    $PSLogging = [PSLogging]::new()
    $PSLogging
}
Export-ModuleMember -Function @('Import-UtilityPSLogging','Update-PSLoggingConfig')