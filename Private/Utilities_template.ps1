<#
    Utilitity class for common tasks.
#>
class Utilities {
    $INPUT_METHOD_PARAMS_TABLE = @{
        GetMethodParamstable        = @("MethodName")
        AddMethodParamstable        = @("MethodName","KeysList")
        CreateItem                  = @("ItemType","Path","WithFeedBack")
        UtilityHashtableValidation  = @("MethodName","UserInputHashtable")
        DisplayMessage              = @("MessageType","MessageCategory","Message")
        UpdateUtilitySettings       = @("UtilityName","UtilityParamsTable")
        GetUtilitySettingsTable     = @("UtilityName")
    }
    $UtilitySettings = @{
        DisplayMessage = @{
            DebugOn     = $true
            Feedback    = $true
            Mute        = $false
        }
    }
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
        # the validation params are defined, making sure the user inputs the correct properties
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
        try{
            $this.INPUT_METHOD_PARAMS_TABLE += @{$myMethodName = $myKeysList}
        }catch{
            $exitConditionMet = $true
        }
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
        $this.HashtableValidation($validationParams)

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
    <#  Description -------------------------------------------------------
            When the input for a method is of type [hashtable], it is often
            the case that you need to validate those keys.
    #>



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
        # start method tasks
        # NOTE: EACH METHOD NAME AND THERE INPUT PARAMETERS NEED TO BE ADDED HERE

        [array]$inputMethodNamesList    = $this.INPUT_METHOD_PARAMS_TABLE.keys
        [string]$inputMethodName        = $fromSender.MethodName
        
        #guard clause: validate MethodName is defined
        $inputExitConditonMet           = $false
        if($inputMethodNamesList -notcontains $inputMethodName){
            $inputExitConditonMet = $true
        }
        if($inputExitConditonMet){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"There is no method defined with the name of '$inputMethodName'."
            Write-Error -Message $msgError ; $Error[0]
            return
        }

        # guard clause: handle case when the inputMethodName from sender is not defined in the INPUT_METHOD_PARAMS_TABLE
        [array]$interalmethodParamsList = $this.INPUT_METHOD_PARAMS_TABLE.$inputMethodName
        if($interalmethodParamsList -eq 0){
            $inputExitConditonMet = $true
        }
        if($inputExitConditonMet){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"None of the supplied keys to UserInputHashtable are defined for '$inputMethodName' in INPUT_METHOD_PARAMS_TABLE."
            Write-Error -Message $msgError ; $Error[0]
        }

        # guard clause: handle keys not defined in INPUT_PARAMS_TABLE
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
                Write-Error -Message $msgError
                return
            }
        }else{
            $itemExists = $true
        }

        if($itemExists){
            $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"'$($fromSender.ItemType)' - '$($fromSender.Path)' was not able to be created, item alredy exists"
            Write-Error -Message $msgError
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
            Write-Error -Message $msgError
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
            Write-Error $msgError
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
                        Write-Error $msgError
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
            MessageType     = 'debug'
            MessageCategory = 'debug'
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
        [string]$myMessageCategory  = $fromSender.MessageCategory
        [string]$myMessageType      = $fromSender.MessageType

        $feedBackTypeList   = @('success','warning','informational')
        $debugTypeList      = @('debug')
        $msgError           = [string]
        switch($myMessageCategory){
            "FeedBack"  {
                if($feedBackTypeList -notcontains $myMessageType){
                    $exitConditionMet = $true
                    $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message type '$($myMessageType)' is undefined under category 'Feedback'."
                }
            }
            "Debug"     {
                if($debugTypeList -notcontains $myMessageType){
                    $exitConditionMet = $true
                    $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message type '$($myMessageType)' is undefined under category 'Debug'."
                }
            }
            default     {
                $exitConditionMet = $true
                $msgError = "[{0}]:: {1}" -f $METHOD_NAME,"The message category '$($myMessageCategory)' is undefined."
            }
        }
        if($exitConditionMet){
            Write-Error $msgError
            return
        }
        
        $mySettings  = $this.GetUtilitySettingsTable(@{UtilityName = 'DisplayMessage'})
        [string]$myMessage  = $fromSender.Message

        ($_ -eq "success") -and ($mySettings.FeedBack -eq $true)
        if($mySettings.Mute -eq $false){
            switch($myMessageType){
                { ($_ -eq "success") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myMessageType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Green
                }
                { ($_ -eq "warning") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myMessageType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Yellow
                }
                { ($_ -eq "informational") -and ($mySettings.FeedBack -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myMessageType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Cyan
                }
                { ($_ -eq "debug") -and ($mySettings.DebugOn -eq $true) }{
                    $msgDisplay = "[{0}]::[{1}]:: {2}" -f $METHOD_NAME,$myMessageType,$myMessage
                    Write-Host $msgDisplay -ForegroundColor Magenta
                }
            }
        }
    }
}
