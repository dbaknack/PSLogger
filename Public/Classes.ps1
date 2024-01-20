# has snippet - imf
$ErrorActionPreference = 'Stop'
Function UTILITIES { . ./Private/Classes.ps1; [Utilities]::new() }

class PSLogger{
    $Configuration = @{
        Headings = @{
            column_01 = 'LogID'
            column_02 = 'UserName'
            column_03 = 'DateTime'
            column_04 = 'HostName'
            column_05 = 'Message'
        }
        Identity = @{
            seed        = 1
            increment   = 1
        }
        DateTimeFormat      = "yyyy-MM-dd HH:mm:ss.fff"
        CycleLogProperites = @{
            EveryInterval = 'seconds'
            IntervalValue = '24'
        }
        MaxLogFiles         = 1
        MaxLogFileEntries   = 1
        LogFileProperties   = @{
            LogsFolderPath  = ''
            Prefix           = ''
            Extension       = ''
            Delimeter       = ''
        }
        TotalLogFiles = 0
        TotalLogEntries = 0
    }
    $UTILITIES = (UTILITIES)
    [void]CreateLogFile(){
        $METHOD_NAME    = "CreateLogFile"
        
        $myExtension    =  $this.Configuration.LogFileProperties.Extension
        $myPrefix        = $this.Configuration.LogFileProperties.Prefix
        
        $logFileList =  $this.GetLogFiles()
        $mostRecent = $logFileList| 
        Select-Object Name, CreationTime, @{Name='CreationTimeDT'; Expression={[DateTime]::Parse($_.CreationTime)} } | 
        Sort-Object CreationTimeDT -Descending | Select-Object -First 1
        $recentID = [int]
        if($mostRecent -match '(test_)(.*)(.csv)'){
          [int]$recentID = $Matches[2]
        }else{
            [int]$recentID = 0
        }

        $myLogNumber    =  ($recentID)+1
        $logFileName    = '{0}{1}{2}' -f $myPrefix,$myLogNumber,$myExtension
        $myLogsFolder   = $this.Configuration.LogFileProperties.LogsFolderPath
        $logFilePath    = '{0}{1}' -f $myLogsFolder,$logFileName

        try{
            $this.UTILITIES.CreateItem(@{
                ItemType        = 'file'
                Path            = $logFilePath
                WithFeedBack    = $false
            })
        }catch{
            $msgError = "There is already a log file with the name '$logFileName' in directory '$myLogsFolder'."
            Write-Error -Message $msgError; $Error[0]
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= "[$METHOD_NAME]:: Log folder created."
            Type 		= "success"
            Category 	= "feedback"
        })
    }
    [void]CreateLogFilesFolder([hashtable]$fromSender){
        $METHOD_NAME        = "CreateLogFilesFolder"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("LogFolderPath")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })

        try{
            $this.UTILITIES.CreateItem(@{
                ItemType        = 'Directory'
                Path            = $fromSender.LogFolderPath
                WithFeedBack    = $false
            })
        }catch{
            $this.UTILITIES.DisplayMessage(@{
                Message 	= "[$METHOD_NAME]:: Log folder already exists created."
                Type 		= "informational"
                Category 	= "feedback"
            })
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= "[$METHOD_NAME]:: Log folder created."
            Type 		= "success"
            Category 	= "feedback"
        })
    }
    [void]SetTotalLogFiles([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetTotalLogFiles"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("Add")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentTotalLogFiles   = $this.GetLogFiles().count
        $myMaxLogValue          = $this.Configuration.MaxLogFiles
        $currentTotalLogFiles   = ($currentTotalLogFiles) + ($fromSender.Add)
        if($currentTotalLogFiles -gt $myMaxLogValue){
            $msgError = "[$METHOD_NAME]:: Cannot create another log file, max limit of '$MyMaxLogValue' has been reached."
            Write-Error -Message $msgError; $Error[0]
            return
        }

        $this.Configuration.TotalLogFiles = $currentTotalLogFiles
    }
    [void]SetMaxLogFileEntries([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetMaxLogFileEntries"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("MaxLogFileEntries")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentMaxLogFileEntries   = $this.Configuration.MaxLogFileEntries
        $newMaxLogFileEntries       = $fromSender.MaxLogFileEntries
        $rangeLimit                 = 1..10000
 
        if(-not($newMaxLogFileEntries.GetType() -eq [int])){
            $msgError = "Max limit has to be of type integer"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($newMaxLogFileEntries -lt $rangeLimit[0]){
            $msgError = "Max limit cannot be less than '$($rangeLimit[0])'"
            Write-Error -Message $msgError; $Error[0]
            return
        }
        
        if($newMaxLogFileEntries -gt $rangeLimit[-1]){
            $msgError = "Max limit cannot be greater than '$($rangeLimit[-1])'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($null -eq $newMaxLogFileEntries){
            $msgError = "Max limit cannot be 'NULL'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($currentMaxLogFileEntries -ne $newMaxLogFileEntries){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME,"Max entry limit updated to '$newMaxLogFileEntries'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.MaxLogFileEntries = $newMaxLogFileEntries
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Max entry limit was not updated since the current limit is the same as the new max limit.")
            Type 		= "debug"
            Category 	= "debug"
        })
    }
    [void]SetMaxLogFiles([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetMaxLogFiles"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("MaxLogFiles")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentMaxLogFiles = $this.Configuration.MaxLogFiles
        $newMaxLogFiles     = $fromSender.MaxLogFiles
        $rangeLimit         = 1..100
 
        if(-not($newMaxLogFiles.GetType() -eq [int])){
            $msgError = "Max limit has to be of type integer"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($newMaxLogFiles -lt $rangeLimit[0]){
            $msgError = "Max limit cannot be less than '$($rangeLimit[0])'"
            Write-Error -Message $msgError; $Error[0]
            return
        }
        
        if($newMaxLogFiles -gt $rangeLimit[-1]){
            $msgError = "Max limit cannot be greater than '$($rangeLimit[-1])'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($null -eq $newMaxLogFiles){
            $msgError = "Max limit cannot be 'NULL'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($currentMaxLogFiles -ne $newMaxLogFiles){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME,"Max limit updated to '$newMaxLogFiles'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.MaxLogFiles = $newMaxLogFiles
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Max limit was not updated since the current limit is the same as the new max limit.")
            Type 		= "debug"
            Category 	= "debug"
        })
    }
    [void]SetLogFileDelimeter([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetLogFileDelimeter"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("Delimeter")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentDelimeter   = $this.Configuration.LogFileProperties.Delimeter
        $newDelimeter       = $fromSender.Delimeter
        $DelimeterList      = @("|",',')

        if($newDelimeter.Length -eq 0){
            $msgError = "Delimeter cannot be of length '0'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($null -eq $newDelimeter){
            $msgError = "Delimeter cannot be 'NULL'"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($DelimeterList -notcontains  $newDelimeter){
            $msgError = "Delimeter can only be '|', or ','"
            Write-Error -Message $msgError; $Error[0]
            return     
        }

        if($currentDelimeter -ne $newDelimeter){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME,"Delimeter updated to '$newDelimeter'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.LogFileProperties.Delimeter = $newDelimeter
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Delimeter was not updated since the current delimeter is the same as the new delimeter.")
            Type 		= "debug"
            Category 	= "debug"
        })   
    }  
    [void]SetLogFileExtension([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetLogFileExtension"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("Extension")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentExtension   = $this.Configuration.LogFileProperties.Extension
        $newExtension       = $fromSender.Extension

        $extensionPattern   = "^\.[a-zA-Z]{3}$"
        if(-not($newExtension -match $extensionPattern)){
            $msgError = "Invalid extension provided, make sure you have a period '.' followed by 3 characters"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        if($currentExtension -ne $newExtension){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME," Log file extension update to '$newExtension'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.LogFileProperties.Extension = $newExtension
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Extension was not updated since the current extension is the same as the new extension.")
            Type 		= "debug"
            Category 	= "debug"
        })    
    }  
    [void]SetLogsFolderPath([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetLogsFolderPath"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("LogFolderPath")
            })
        }

        $this.UTILITIES.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
    
        $currentPath    = $this.Configuration.LogFileProperties.LogsFolderPath
        $newPath        = $fromSender.LogFolderPath

        if($currentPath -ne $newPath){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME," Log folder path update to '$($fromSender.LogFolderPath)'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.LogFileProperties.LogsFolderPath = $newPath
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Path was not updated since the current path is the same as the new path.")
            Type 		= "debug"
            Category 	= "debug"
        })    
    }
    [void]SetLogFilePrefix([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $METHOD_NAME        = "SetLogFilePrefix"
        $myMessage          = "[{0}]:: {1}"
        $methodParamsAdded  = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = ($myMessage -f $METHOD_NAME,"Adding method required paramters to INPUT_PARAMS_TABLE")
                Category    = "debug"
                Type        = "debug"
            })

            $this.UTILITIES.AddMethodParamstable(@{
                MethodName  = $METHOD_NAME
                KeysList    = @("LogFilePrefix")
            })
        }

        $currentPrefix  = $this.Configuration.LogFileProperties.Prefix
        $newPrefix      = $fromSender.LogFilePrefix

        $prefixPatter = "^.+_$"
        if(-not($newPrefix -match $prefixPatter)){
            $msgError = "Prefix does not match the set pattern, make sure your prefix has leading string of any length with a trailing '_'."
            Write-Error -Message $msgError; $Error[0]
            return
        }
        
        if($currentPrefix -ne $newPrefix){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME,"Prefix updated to '$($fromSender.LogFilePrefix)'")
                Type 		= "success"
                Category 	= "feedback"
            })
            $this.Configuration.LogFileProperties.Prefix = $fromSender.LogFilePrefix
            return
        }

        $this.UTILITIES.DisplayMessage(@{
            Message 	= ($myMessage -f $METHOD_NAME,"Prefix was not updated since the current prefix is the same as the new prefix.")
            Type 		= "debug"
            Category 	= "debug"
        })      
    }
    [void]Initalize([hashtable]$fromSender){
        $METHOD_NAME = 'Initalize'
        $methodParamsAdded = $this.UTILITIES.GetMethodParamstable(@{ MethodName = $METHOD_NAME })
        $myMessage = '[{0}]:: {1}'
        if($methodParamsAdded -eq 0){
            $this.UTILITIES.DisplayMessage(@{
                Message     = "Methods will be added to INPUT_METHOD_PARAMS_TABLE."
                Category    = "debug"
                Type        = "debug"
            })

            $myMethodParams = @{
                MethodName  = "Initalize"
                KeysList    = @(
                    "MaxLogFileEntries",
                    "MaxLogFiles",
                    "Delimeter",
                    "Extension",
                    "LogFilePrefix",
                    "LogFolderPath",
                    #-----------------------#
                    "CacheSettingsFolderPath",      #= './CacheFolder'
                    "CacheFileName",                # = '/LoggingCache.txt'
                    "ConfigurationLabel"             # = "LoggingCache"
                )
            }
            $this.UTILITIES.AddMethodParamstable($myMethodParams)
        }

        # check: if there is configurations saved
        $myConfiguration = $null
        $configSetFromCache = [bool]
        if(Test-Path -path "$($fromSender.CacheSettingsFolderPath)$($fromSender.CacheFileName)"){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= "[$METHOD_NAME]:: Cache Exists already, using that"
                Type 		= "informational"
                Category 	= "feedback"
            })  
           $myConfiguration =  $this.UTILITIES.ReadCacheConfiguration(@{
                Configuration    = $this.Configuration
                FolderPath      = $fromSender.CacheSettingsFolderPath
                FileName        = $fromSender.CacheFileName
                ConfigurationLabel = $fromSender.ConfigurationLabel
            })
            $this.Configuration = $myConfiguration
            $configSetFromCache = $true
        }else{
            $configSetFromCache = $false
        }

        if($configSetFromCache -eq $true){
            $this.UTILITIES.DisplayMessage(@{
                Message 	= ($myMessage -f $METHOD_NAME,"Configuration set from cache.")
                Type 		= "debug"
                Category 	= "debug"
            })   
        }

        $this.SetMaxLogFileEntries(@{MaxLogFileEntries = $fromSender.MaxLogFileEntries})
        $this.SetMaxLogFiles(@{MaxLogFiles = $fromSender.MaxLogFiles})
        $this.SetLogFileDelimeter(@{Delimeter = $fromSender.Delimeter})
        $this.SetLogFileExtension(@{Extension = $fromSender.Extension})
        $this.SetLogFilePrefix(@{LogFilePrefix = $fromSender.LogFilePrefix})
        $this.SetLogsFolderPath(@{LogFolderPath = $fromSender.LogFolderPath})

        $this.CreateLogFilesFolder(@{LogFolderPath = $fromSender.LogFolderPath})
        $this.SetTotalLogFiles(@{Add = 1})
        $this.CreateLogFile()

        $myConfiguration = $this.Configuration
        $this.UTILITIES.CacheConfiguration(@{
            Configuration       = $myConfiguration
            FolderPath         = $fromSender.CacheSettingsFolderPath
            FileName           = $fromSender.CacheFileName
            ConfigurationLabel  = $fromSender.ConfigurationLabel
        })
    }
    [psobject]GetLogFiles(){
        $myPrefix = $this.Configuration.LogFileProperties.Prefix
        $myPattern = "$($myPrefix)*"

        $myLogFolder = $this.Configuration.LogFileProperties.LogsFolderPath

        $matchingFiles = Get-ChildItem -Path $myLogFolder -Filter "$myPattern"  -File
        return $matchingFiles
    }
    [psobject]GetOldestLog(){
        $myLogFiles = $this.GetLogFiles()
        $lastLogFile = $myLogFiles| 
        Select-Object Name, CreationTime, @{Name='CreationTimeDT'; Expression={[DateTime]::Parse($_.CreationTime)} } | 
        Sort-Object CreationTimeDT -Descending | Select-Object -Last 1
        return $lastLogFile
    }
    [psobject]GetLatestLog(){
        $myLogFiles = $this.GetLogFiles()
        $lastLogFile = $myLogFiles| 
        Select-Object Name, CreationTime, @{Name='CreationTimeDT'; Expression={[DateTime]::Parse($_.CreationTime)} } | 
        Sort-Object CreationTimeDT -Descending | Select-Object -First 1
        return $lastLogFile
    }
    [void]RemoveAllLogs([hashtable]$fromSender){
        # adding the methods params to INPUT_METHOD_PARAMS_TABLE allows you to handle keys are
        # correctly provided
        $myLogFolder        = $this.Configuration.LogFileProperties.LogsFolderPath
        $myPrefix            = $this.Configuration.LogFileProperties.Prefix
        Get-ChildItem -Path $myLogFolder -Filter "$myPrefix*"  -File | ForEach-Object { Remove-Item $_.FullName -Force }

        $myConfigurationProperties = $this.UTILITIES.GetUtilitySettingsTable(@{UtilityName = 'Configuration'})
        $myCache = $myConfigurationProperties.($fromSender.ConfigurationLabel)
        $myCacheProperties = (get-content -path $myCache.FilePath) | ConvertFrom-Json
        
        $myCacheProperties.TotalLogEntries  = 0
        $myCacheProperties.TotalLogFiles    = 0
        $myNewJson = $myCacheProperties | ConvertTo-Json
        Set-Content -path ($myCache.FilePath) -Value $myNewJson
        $this.Configuration = $myCacheProperties
    }
    [psobject]CheckInterval(){
        $myCycleLogProperties = $this.Configuration.CycleLogProperites
        $myInterval = $myCycleLogProperties.EveryInterval
        $myIntervalValue = $myCycleLogProperties.IntervalValue

        $DateTimeOffset = switch($myInterval){
            'hours'{
                (Get-Date).AddHours(-$myIntervalValue)
            }
            'seconds'{
                (Get-Date).AddSeconds(-$myIntervalValue)
            }
            'minutes'{
                (Get-Date).AddMinutes(-$myIntervalValue)
            }
            'days'{
                (Get-Date).AddDays(-$myIntervalValue)
            }
        }
        # is the latest log older than the set offset?
       $myLatestLogFile =  $this.GetLatestLog()
       $isOlder = $myLatestLogFile.CreationTime -lt $DateTimeOffset
       return $isOlder
    }
}
$PSLogger2 = [PSLogger2]::new()
$PSLogger2.Initalize(@{
    MaxLogFileEntries       = 5
    MaxLogFiles             = 5
    Delimeter               = ','
    Extension               = '.csv'
    LogFilePrefix            = 'test_'
    LogFolderPath           = './TestLogFolder/'
    CacheSettingsFolderPath = './CacheFolder'
    CacheFileName           = '/LoggingCache.txt'
    ConfigurationLabel       = "LoggingCache"
})
$PSLogger2.CheckInterval()
$PSLogger2.RemoveAllLogs(@{ConfigurationLabel= "LoggingCache"})
$PSLogger2.GetLogFiles()