$ErrorActionPreference = 'Stop'
Function ConvertFrom-Hashtable {
    [CmdletBinding()]
    Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [hashtable]$MyHashtable
    )
    PROCESS {
        $results = @()

        $MyHashtable | ForEach-Object{
            $result = New-Object psobject;
            foreach ($key in $_.keys) {
                $result | Add-Member -MemberType NoteProperty -Name $key -Value $_[$key]
             }
             $results += $result;
         }
        return $results
    }
}
class JsonConverter {
    [object]ConvertFromJson([object]$Object) {
        if ($Object -is [System.Management.Automation.PSCustomObject]) {
            $hashTable = @{}
            foreach ($property in $Object.PSObject.Properties) {
                $hashTable[$property.Name] = $this.ConvertFromJson($property.Value)
            }
            return $hashTable
        }
        elseif ($Object -is [System.Collections.ArrayList]) {
            return $Object.ForEach({ $this.ConvertFromJson($property.Value)})
        }
        elseif ($Object -is [System.Collections.Generic.Dictionary[string, object]]) {
            $hashTable = @{}
            foreach ($entry in $Object) {
                $key = $entry.Key
                $value = $this.ConvertFromJson($Object.Value)
                $hashTable[$key] = $value
            }
            return $hashTable
        }
        else {
            return $Object
        }
    }
}
Function JsonConverter{[JsonConverter]::new()}

class UTILITIES {
    <#  Description -------------------------------------------------------
            This class parameter acts as a table for internal utilities.
            You may add more to the table as needed.
    #>
    $INPUT_METHOD_PARAMS_TABLE = @{
        GetMethodParamstable        = @("MethodName")
        AddMethodParamstable        = @("MethodName","KeysList")
        CreateItem                  = @("ItemType","Path","WithFeedBack")
        UtilityHashtableValidation  = @("MethodName","UserInputHashtable")
        DisplayMessage              = @("Type","Category","Message")
        UpdateUtilitySettings       = @("UtilityName","UtilityParamsTable")
        GetUtilitySettingsTable     = @("UtilityName")
        GetUtilityMethodList        = @("GetAllMyUtilities")
        CreateCache                 = @("FolderPath","FileName")
        CacheConfiguration          = @("Configuration","FolderPath","FileName","ConfigurationLabel")
        ReadCacheConfiguration      = @("Configuration","FolderPath","FileName","ConfigurationLabel")
        ReadMyCacheConfiguration    = @("ConfigurationLabel")
        UpdateCacheConfiguration    = @("Configuration","ConfigurationLabel")
    }
    <#  Description -------------------------------------------------------
            This class parameter is how you control some of the itilities
            defined in the class.
    #>
    $UtilitySettings = @{
        DisplayMessage = @{
            DebugOn     = $true
            Feedback    = $true
            Mute        = $false
        }
    }
    $JsonConverter = (JsonConverter)
    [void]AddMethodParamstable([hashtable]$fromSender){
        <#
            #example usage:
            $methodParams = @{
                MethodName = 'TestItemExists'
                KeysList = @('key1','key2')
            }
            $UTILITY.AddMethodParamstable($methodParams)
        #>
        # all methods define there method name
        $METHOD_NAME        = "AddMethodParamstable"
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }
        $this.HashtableValidation($validationParams)

        # if hashtable is valid, the method name from sender is used to retried the values requested
        $getMethodParams = @{
            MethodName = $fromSender.MethodName
        }
        if(($this.GetMethodParamstable($getMethodParams))-ne 0){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"Method '$($fromSender.MethodName)' already exists in INPUT_METHOD_PARAMS_TABLE."
            Write-Error -Message $msgError ; $Error[0]
            return
        }

        [string]$myMethodName   = $fromSender.MethodName
        [array]$myKeysList      = $fromSender.KeysList
        $this.INPUT_METHOD_PARAMS_TABLE += @{$myMethodName = $myKeysList}
    }
    [psobject]GetMethodParamstable([hashtable]$fromSender){
        <#
            #example usage
            $getMethodParams = @{
                MethodName = 'AddMethodParamstable'
            }
            $UTILITY.GetMethodParamstable($getMethodParams)
        #>
        # all methods define there method name
        $METHOD_NAME                = "GetMethodParamstable"

        # the validation params are defined, making sure the user inputs the correct properties
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }

        #$exitConditionMet   = $false
        $methodParamsExists = $true
        # if hashtable is valid the methodname from sender is used to retriev the values requested
        $myMethodName   = $fromSender.MethodName
        $myMethodParams = $this.INPUT_METHOD_PARAMS_TABLE.$myMethodName

        if($null -eq $myMethodParams){
            $methodParamsExists = $false
        }

        if($methodParamsExists -eq $false){
            return 0
        }
        return $myMethodParams
    }
    [void]HashtableValidation([hashtable]$fromSender){
        <#  Instructions -------------------------------------------------------
            Step 1:
                In order to validate the hashtable you are using as input for a
                given method; you'll need to define the method name, and the 
                hashtable keys.

                AddMethodParamstable(@{
                    MethodName  = 'MyMethodName'
                    KeysList    = @('key1','key2')
                })

            Step 2:
                Within the method you intend to use this method in, you need to
                invoke this method in the following way.

                $UTILITY.HashtableValidation(@{
                    MethodName          = 'MyMethodName'
                    UserInputHashtable  = $myHashtable
                })
        #>
        #region:    Self Validation
        <#
                Remarks ---------------------------------------------------------
                HashtableValidation validates itself each time other things need
                to be validated. The commands defined within
                #region: Self Validation are commands applicable to
                HashtableValidation only.
        #>
        $METHOD_NAME                = "UtilityHashtableValidation"
        $METHOD_PARAMS_LIST         = @("MethodName","UserInputHashtable")
        [array]$USER_PARAMS_LIST    = $fromSender.Keys
        $exitConditionMet           = $false

        # guard clause: handle a null passed parameter
        if($USER_PARAMS_LIST.count -eq 0){
            $exitConditionMet = $true
        }

        if($exitConditionMet){
            $msgError = "{0}:: {1}" -f $METHOD_NAME,"Input parameter cannot be null."
            Write-Error -Message $msgError ; $Error[0]
            return
        }

        # guard clause: handle keys not defined in METHOD_PARAMAS_LIST
        $undefinedUserParamList = @()
        foreach($userParam in $USER_PARAMS_LIST){
            if($METHOD_PARAMS_LIST -notcontains $userParam){
                $undefinedUserParamList += $userParam
                $exitConditionMet = $true
            }
        }
        if($exitConditionMet){
            $undefinedUserParamList -join ', '
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The following paramter(s) is/are not defined '$undefinedUserParamList'."
            Write-Error -Message $msgError ; $Error[0]
            return
        }

        #guard clause: the keys provided are the keys defined and no less
        $definedUserParamCount      = $METHOD_PARAMS_LIST.count
        $definedUserParamList       = @()
        $counter                    = 0
        foreach($methodParams in $METHOD_PARAMS_LIST){
            foreach($userParam in $USER_PARAMS_LIST){
                $definedUserParamList += $userParam
            }
            $counter++ 
        }
        if($counter -ne $definedUserParamCount){
            $exitConditionMet = $true
        }

        if($exitConditionMet){
            $undefinedUserParamList -join ', '
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The following paramter(s) are missing '$definedUserParamList'."
            Write-Error -Message $msgError ; $Error[0]
            return
        }
        #endregion: Self Validation

        #   - define the method names in the class parameters for use internally in this method
        #   - define the method name to validate
        [array]$inputMethodNamesList    = $this.INPUT_METHOD_PARAMS_TABLE.keys
        [string]$inputMethodName        = $fromSender.MethodName
        
        #   - (guard_clause): check that the method name provided exists in the class properties definiton 
        $inputExitConditonMet           = $false
        if($inputMethodNamesList -notcontains $inputMethodName){
            $inputExitConditonMet = $true
        }
        if($inputExitConditonMet){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"There is no method defined with the name of '$inputMethodName'."
            Write-Error -Message $msgError ; $Error[0]
            return
        }
        #   - (guard_clause): check tha the method name provided values count is not empty
        [array]$interalmethodParamsList = $this.INPUT_METHOD_PARAMS_TABLE.$inputMethodName
        if($interalmethodParamsList -eq 0){
            $inputExitConditonMet = $true
        }
        if($inputExitConditonMet){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"None of the supplied keys to UserInputHashtable are defined for '$inputMethodName' in INPUT_METHOD_PARAMS_TABLE."
            Write-Error -Message $msgError ; $Error[0]
            return
        }

        #   - (guard_clause): the keys provided to this method are checked against the ones stowed in the class properties
        [array]$inputUserParamsList      = $fromSender.UserInputHashtable.keys
        $inputUndefinedUserParamList = @()
        foreach($inputUserParam in $inputUserParamsList){
            if($interalmethodParamsList -notcontains $inputUserParam){
                $inputUndefinedUserParamList += $inputUserParam
                $exitConditionMet = $true
            }
        }
        if($exitConditionMet){
            $inputUndefinedUserParamList -join ', '
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The following paramter(s) is/are not defined in the INPUT_PARAMS_TABLE '$inputUndefinedUserParamList'."
            Write-Error -Message $msgError ; $Error[0]
            return
        }
    }
    [psobject]GetUtilityMethodList([hashtable]$fromSender){
        <#
        # example usage:
        CreateItem(@{GetAll = $true}) 
        #>
        #region: Validation
        $METHOD_NAME        = "GetUtilityMethodList"
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        $exitConditionMet   = $false
        $msgError           = [string]
        $inputValue = ($fromSender.GetAllMyUtilities)
        if($inputValue -eq $false){
            $exitConditionMet = $true
            
        }

        if($exitConditionMet){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME, "Unput is only allowed to be `$true."
            Write-Error -Message $msgError
            return $Error[0]
        }

        [array]$myMethodList = $this.INPUT_METHOD_PARAMS_TABLE.keys
        return $myMethodList
    }
    [void]CreateItem([hashtable]$fromSender){
        <#
        # example usage:
        $createItemParams = @{
            ItemType        = 'Directory'
            Path            = "./test2"
            WithFeedBack    = $false
        }
        $UTILITY.CreateItem($createItemParams)
        #>
        # all methods define there method name
        $METHOD_NAME        = "CreateItem"
        $exitConditionMet   = $false
        # the validation params are defined, making sure the user inputs the correct properties
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }
        $this.HashtableValidation($validationParams)

        [string]$path = $fromSender.Path
        [string]$itemType = $fromSender.ItemType
        $itemExists = $false
        if(-not(Test-Path -Path $path)){
            try{
                $exitConditionMet = $false
                New-Item -Path $path -ItemType $itemType | Out-Null
            }catch{
                $exitConditionMet = $true
            }

            if($exitConditionMet){
                $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"'$($fromSender.ItemType)' - '$($fromSender.Path)' was not able to be created"
                Write-Error -Message $msgError; $Error[0]
                return
            }
        }else{
            $itemExists = $true
        }

        if($itemExists){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"'$($fromSender.ItemType)' - '$($fromSender.Path)' was not able to be created, item alredy exists"
            Write-Error -Message $msgError; $Error[0]
            return
        }

        $withFeedBack = $fromSender.WithFeedBack
        switch($withFeedBack){
            $true{
                $msgState = "[{0}]:: {1}" -f $METHOD_NAME,"'$($fromSender.ItemType)' - '$($fromSender.Path)' successfully created"
                Write-Host $msgState -ForegroundColor Cyan
            }
            $false{
                # nothing is displayed when the WithFeedback Option is false
            }
            default{
                $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"WithFeedBack parameter is undefined."
                Write-Error -Message $msgError; $Error[0]
                return
            }
        }
    }
    [psobject]GetUtilitySettingsTable([hashtable]$fromSender){
        <#
            # example usage
            $util.GetUtilitySettingsTable(@{UtilityName = 'DisplayMessage'})
        #>

        # all methods define there method name
        $METHOD_NAME            = "GetUtilitySettingsTable"
        $utilitySettingsExists  = [bool]
        # the validation params are defined, making sure the user inputs the correct properties
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }
        $this.HashtableValidation($validationParams)
        # if hashtable is valid the methodname from sender is used to retried the values requested
        $myUtilityName          = $fromSender.UtilityName
        $myUtilitySettings      = $this.UtilitySettings.$myUtilityName

        if($null -eq $myUtilitySettings){
            $utilitySettingsExists = $false
        }

        if($utilitySettingsExists -eq $false){
            return 0
        }
        return $myUtilitySettings
    }
    [void]UpdateUtilitySettings([hashtable]$fromSender){
        <#
            #example usage:
            $utilitySettingsParams = @{
                UtilityName = 'DisplayMessage'
                UtilityParamsTable = @{
                    DebugOn     = $true
                    Feedback    = $true
                    Mute        = $false
                }
            }
            $util.UpdateUtilitySettings($utilitySettingsParams)
        #>
        # all methods define there method name
        $METHOD_NAME        = "UpdateUtilitySettings"
        $exitConditionMet   = $false
        # the validation params are defined, making sure the user inputs the correct properties
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }
        $this.HashtableValidation($validationParams)

        [string]$myUtilityName = $fromSender.UtilityName
        $myUtilityParams = $this.GetUtilitySettingsTable(@{UtilityName = $myUtilityName})

        if(0 -eq $myUtilityParams){
            $exitConditionMet = $true
            $msgError =  "[{0}]:: {1}" -f $METHOD_NAME, "The utility '$myUtilityName' is dont defined."
            Write-Error $msgError; $Error[0]
        }

        if($exitConditionMet){
            return
        }

        switch($myUtilityName){
            'DisplayMessage' {
                [array]$UtilityParamList        = $myUtilityParams.keys
                [array]$InputUtilityParamList   = $fromSender.UtilityParamsTable.keys
                foreach($inputUtilityParam in $InputUtilityParamList){
                    if($utilityParamList -notcontains $inputUtilityParam){
                        $exitConditionMet = $true
                        $msgError =  "[{0}]:: {1}" -f $METHOD_NAME, "The utility parameter '$inputUtilityParam' is not defined."
                        Write-Error $msgError; $Error[0]
                        return
                    }
                }
                $this.UtilitySettings.DisplayMessage.DebugOn     = $fromSender.UtilityParamsTable.DebugOn
                $this.UtilitySettings.DisplayMessage.Mute        = $fromSender.UtilityParamsTable.Mute
                $this.UtilitySettings.DisplayMessage.FeedBack    = $fromSender.UtilityParamsTable.FeedBack 
            }
        }
    }
    [void]DisplayMessage([hashtable]$fromSender){
        <#
        #example usage:
        $displayMsgParams = @{
            Message         = 'test'
            Type     = 'debug'
            Category = 'debug'
        }
        $util.DisplayMessage($displayMsgParams)
        #>
        # all methods define there method name
        $METHOD_NAME        = "DisplayMessage"
        $exitConditionMet   = $false
        # the validation params are defined, making sure the user inputs the correct properties
        $validationParams = @{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        }
        $this.HashtableValidation($validationParams)
        [string]$myCategory  = $fromSender.Category
        [string]$myType      = $fromSender.Type

        $feedBackTypeList   = @('success','warning','informational')
        $debugTypeList      = @('debug')
        $msgError           = [string]
        switch($myCategory){
            "FeedBack"  {
                if($feedBackTypeList -notcontains $myType){
                    $exitConditionMet = $true
                    $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message type '$($myType)' is undefined under category 'Feedback'."
                }
            }
            "Debug"     {
                if($debugTypeList -notcontains $myType){
                    $exitConditionMet = $true
                    $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message type '$($myType)' is undefined under category 'Debug'."
                }
            }
            default     {
                $exitConditionMet = $true
                $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message category '$($myCategory)' is undefined."
            }
        }
        if($exitConditionMet){
            Write-Error $msgError
        }
        
        $mySettings  = $this.GetUtilitySettingsTable(@{UtilityName = 'DisplayMessage'})
        [string]$myMessage  = $fromSender.Message

        ($_ -eq "success") -and ($mySettings.FeedBack -eq $true)
        if($mySettings.Mute -eq $false){
            switch($myType){
                { ($_ -eq "success") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Green
                }
                { ($_ -eq "warning") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Yellow
                }
                { ($_ -eq "informational") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Cyan
                }
                { ($_ -eq "debug") -and ($mySettings.DebugOn -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Magenta
                }
            }
        }
    }
    [void]CreateCache([hashtable]$fromSender){
        <#Instructions -----------------------------------
            SetCache(@{
                FolderPath  = './CacheFolder'
                FileName    = '/LoggingCache.txt' 
            })
        #>
        #region: Validation
        $METHOD_NAME        = "CreateCache"
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        $msg = "[{0}]> {1}"
        $messageParams = @{
            Message     = ''
            Type        = [string]
            Category    = [string]
        }
        #see if the folder exist
        $cacheFolder        = $fromSender.FolderPath
        $cacheFolderExists  = (Test-Path $cacheFolder)
        $createCacheFolder  = [bool]
        if($cacheFolderExists -eq $false){
            $createCacheFolder = $true
        }else{
            $createCacheFolder = $false
        }

        $messageParams.Type     = "debug"
        $messageParams.Category = "debug"
        if($createCacheFolder){
            $messageParams.Message  = $msg -f $METHOD_NAME,"Cache folder $cacheFolder needs to be created."
            $this.DisplayMessage($messageParams)
        }else{
            $messageParams.Message  = $msg -f $METHOD_NAME,"Cache folder $cacheFolder already exist."
            $this.DisplayMessage($messageParams)
        }

        # create the cache folder
        $messageParams.Category = "feedback"
        if($cacheFolderExists -eq $false){
            try{
                $messageParams.Type     = "success"
                $messageParams.Message  = $msg -f $METHOD_NAME,"Cache folder $cacheFolder created."
                $this.CreateItem(@{
                    ItemType        = "Directory"
                    Path            = $cacheFolder
                    WithFeedBack    = $false
            })
            }catch{
                $messageParams.Type = "warning"
                $messageParams.Message  = $msg -f $METHOD_NAME,"Cache folder $cacheFolder  was not created."
            }
            $this.DisplayMessage($messageParams)
        }

        # create the cache file
        $cacheFolderExists  = (Test-Path $cacheFolder)
        $cacheFileName      = $fromSender.FileName
        $cacheFilePath      = "$($cacheFolder)$($cacheFileName)"      
        $createCacheFile    = [bool]
        $cacheFileExists    = (Test-Path $cacheFilePath)
        if($cacheFileExists){
            $createCacheFile = $false
        }else{
            $createCacheFile = $true
        }

        $messageParams.Type     = "debug"
        $messageParams.Category = "debug"
        if($createCacheFile -eq $true){
            $messageParams.Message  = $msg -f $METHOD_NAME,"Cache file $cacheFileName needs to be created."
            $this.DisplayMessage($messageParams)
        }else{
            $messageParams.Message  = $msg -f $METHOD_NAME,"Cache file $cacheFileName already exist."
            $this.DisplayMessage($messageParams)
        }

        $messageParams.Category = "feedback"
        if($createCacheFile -eq $true){
            try{
                $messageParams.Type     = "success"
                $messageParams.Message  = $msg -f $METHOD_NAME,"Cache file $cacheFolder created."
                $this.CreateItem(@{
                    ItemType        = "file"
                    Path            = $cacheFilePath
                    WithFeedBack    = $false
            })
            }catch{
                $messageParams.Type     = "warning"
                $messageParams.Message  = $msg -f $METHOD_NAME,"Cache file $cacheFolder  was not created."
            }
            $this.DisplayMessage($messageParams)
        }
    }
    [void]CacheConfiguration([hashtable]$fromSender){
        #region: Validation
        $METHOD_NAME        = "CacheConfiguration"
        $exitConditionMet   = $false
        $msgError           = [string]
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        #region: message params
        $msg = "[{0}]> {1}"
        #endregion: message params

        $myCacheFolderPath  = $fromSender.FolderPath
        $myCacheFileName    = $fromSender.FileName
        $myCacheFilePath    = "$($myCacheFolderPath)$($myCacheFileName)"

        # cache is only created if it already doesnt exist
        $cacheExist = (Test-Path -Path $myCacheFolderPath)

        # messages 
        if($cacheExist -eq $true){
            $this.DisplayMessage(@{
                Message     = ($msg -f $METHOD_NAME, "Cache '$($myCacheFolderPath)' already exists.")
                Category    = "debug"
                Type        = "debug"
            })
        }
        if($cacheExist -eq $false){
            $this.DisplayMessage(@{
                Message     = ($msg -f $METHOD_NAME, "Cache '$($myCacheFolderPath)' doesnt exists.")
                Category    = "debug"
                Type        = "debug"
            })
        }
        if($cacheExist -eq $false){
            $cacheCreationFailed = [bool]
            try{
                $cacheCreationFailed = $false
                $this.CreateCache(@{
                    FolderPath      = $myCacheFolderPath
                    FileName        = $myCacheFileName }
                )
            }catch{
                $cacheCreationFailed = $true
                $msgError = "[{0}]:: {1}"
                $msgError = $msgError -f $METHOD_NAME,"cache was not created"
            }
    
            if($cacheCreationFailed -eq $true){
                $exitConditionMet = $true
            }
    
            if($exitConditionMet -eq $true){
                Write-Error -Message $msgError ; $Error[0]
                return
            }
        }

        $isValidConfigType = ($fromSender.Configuration).GetType() -eq [hashtable]
        if($isValidConfigType -eq $false){
            $exitConditionMet = $true
            $msgError = "[{0}]:: {1}"
            $msgError = $msgError -f $METHOD_NAME,"configuration is not in the correct format, needs to be a hashtable."
        }

        if($exitConditionMet){
            Write-Error -Message $msgError; $Error[0]
            return
        }

        $myConfigurationTable = $fromSender.configuration
        $myConfigurationJson = $myConfigurationTable | ConvertTo-Json
        
        Set-Content -path $myCacheFilePath -Value $myConfigurationJson

        $this.DisplayMessage(@{
            Message  =  ($msg -f $METHOD_NAME,"Configuration saved to file '$($myCacheFilePath)'.")
            Type     = 'success'
            Category = 'Feedback'
        })

        $configSettings = $this.GetUtilitySettingsTable(@{UtilityName = 'Configuration'})
        if($configSettings -eq 0){
            $settingGroupAdded = $true
            $this.UtilitySettings.Add("Configuration",@{})
        }

        $configurationLable = $fromSender.ConfigurationLabel
        if($null -eq $configurationLable){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"configuration lable cannot be null."
            Write-Error -Message $msgError;$Error[0]
            return
        }
        
        [array]$configurationGroupList= $this.UtilitySettings.Configuration.keys
        if($configurationGroupList -notcontains $configurationLable){
            $this.UtilitySettings.Configuration.Add($configurationLable,@{
                FilePath = $myCacheFilePath
                FolderPath = $myCacheFolderPath
                FileName = $myCacheFileName
            })
        }else{
            $this.DisplayMessage(@{
                Message  =  ($msg -f $METHOD_NAME,"Configuration group '$configurationLable' already exists.")
                Type     = 'debug'
                Category = 'debug'
            })
        }
    }
    [psobject]ReadCacheConfiguration([hashtable]$fromSender){
        <#
        #region: test ReadCacheConfiguration
        $fromSender = @{
            Configuration   = $PSLogger2.Configuration
            FolderPath      = './CacheFolder'
            FileName        = '/LoggingCache.txt' 
        }
        $UTILITIES.ReadCacheConfiguration($fromSender)

        $fromSender = @{
            Configuration   = $null
            FolderPath      = './CacheFolder'
            FileName        = '/LoggingCache.txt' 
        }
        $UTILITIES.ReadCacheConfiguration($fromSender)

        #endregion: test ReadCacheConfiguration
        #>
        #region: Validation
        $METHOD_NAME        = "ReadCacheConfiguration"
        $msgError           = [string]
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        #region: message params
        $msg = "[{0}]> {1}"
        #endregion: message params
        $myCacheFolderPath  = $fromSender.FolderPath
        $myCacheFileName    = $fromSender.FileName
        $myCacheFilePath    = "$($myCacheFolderPath)$($myCacheFileName)"
        $myCacheExists = switch(Test-Path -Path $myCacheFilePath){
            $true   {
                $this.DisplayMessage(@{
                    Message = ($msg -f $METHOD_NAME,"The cache file '$($myCacheFilePath)' exists.")
                    Type = "debug"
                    Category = "debug"
                })
                $true
            }
            $false  {
                $this.DisplayMessage(@{
                    Message = ($msg -f $METHOD_NAME,"The cache file '$($myCacheFilePath)' doesnt exists.")
                    Type = "debug"
                    Category = "debug"
                })
                $false}
        }

        $myConfiguration = $fromSender.Configuration
        $createCache = switch($myCacheExists){
            $false { $true }
            $true { $false }
        }
        
        $isNullConfig = $true
        if($null -ne $myConfiguration){
            $isNullConfig = $false
        }

        if($myCacheExists -eq $false){
            # cache creation is true, and null is false
            if(($createCache -eq $true) -and ($isNullConfig -eq $false)){
                $this.CacheConfiguration(@{
                    Configuration = ($fromSender.Configuration)
                    FolderPath      = $myCacheFolderPath
                    FileName        = $myCacheFileName
                    ConfigurationLabel = $fromSender.ConfigurationLabel
                })
            }else{
                $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"Can only create attempt to createcache when configuration is not null."
                Write-Error -Message $msgError
                return $Error[0]
            }
        }

        $cacheReadable = [bool]
        $myConfigObject = $null
        try{
            $cacheReadable = $true
            $myConfigObject = Get-Content -Path $myCacheFilePath -ErrorAction "Stop"
        }catch{
            $this.DisplayMessage(@{
                Message = ($msg -f $METHOD_NAME,"The cache file '$($myCacheFilePath)' content could not be read.")
                Type = "debug"
                Category = "debug"
            })
            $cacheReadable = $false
        }

        if($cacheReadable -eq $false){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"Cache content was not accessable..."
            Write-Error -Message $msgError
            return $Error[0]
        }

        if($null -eq $myConfigObject){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"Cache does not contain any information"
            Write-Error -Message $msgError
            return $Error[0]
        }

        $isConvertable = [bool]
        $myConfigTable = $null
        try{
            $isConvertable = $true
            $myConfigTable = $myConfigObject | ConvertFrom-Json -ErrorAction "Stop"
        }catch{
            $isConvertable = $false
        }
        
        if(-not($isConvertable)){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"Cache is not formatted in proper json format."
            Write-Error -Message $msgError
            return  $Error[0]
        }

        $myConfigTable = $this.JsonConverter.ConvertFromJson($myConfigTable)
        return $myConfigTable
    }
    [psobject]ReadMyCacheConfiguration([hashtable]$fromSender){
        #region: Validation
        $METHOD_NAME        = "ReadMyCacheConfiguration"
        #$exitConditionMet   = $false
        #$msgError           = [string]
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        #region: message params
        #$msg = "[{0}]> {1}"
        #endregion: message params
        $ConfigSettings = $this.GetUtilitySettingsTable(@{UtilityName = 'Configuration'}).($fromSender.ConfigurationLabel)
        return $this.ReadCacheConfiguration(@{
            FileName = $ConfigSettings.FileName
            FolderPath = $ConfigSettings.FolderPath
            Configuration = $null
        })
    }
    [void]UpdateCacheConfiguration([hashtable]$fromSender){
        #region: Validation
        $METHOD_NAME        = "UpdateCacheConfiguration"
        #$exitConditionMet   = $false
        #$msgError           = [string]
        $this.HashtableValidation(@{
            MethodName          = $METHOD_NAME
            UserInputHashtable  = $fromSender
        })
        #endregion: Validation
        $updatable = $this.GetUtilitySettingsTable(@{UtilityName = 'Configuration'})
        if($updatable -eq 0){
            $this.DisplayMessage(@{
                Message = "There is no conifguration defined to update."
                Type = "debug"
                Category = "debug"
            })
        }
        [string]$utilitySettingLabel    = $fromSender.ConfigurationLabel
        $myConfiguration  = $this.GetUtilitySettingsTable(@{
            UtilityName = 'Configuration'})
        $myConfigurationSettings = $myConfiguration.$utilitySettingLabel
        $this.CacheConfiguration(@{
            Configuration       = $fromSender.Configuration
            FolderPath          = $myConfigurationSettings.FolderPath
            FileName            = $myConfigurationSettings.FileName
            ConfigurationLabel  = $utilitySettingLabel
        })
    }
}