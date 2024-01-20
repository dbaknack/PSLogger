Function Get-UDFVerbosePreferences([switch]$useGlobalVerbosePreferences,[string]$VerboseMessage){
    if($useGlobalVerbosePreferences){
        $INHERITED_VERBOSE_PREFERENCE = $VerbosePreference
    }else{
        $INHERITED_VERBOSE_PREFERENCE = 'Continue'
    }
    switch($INHERITED_VERBOSE_PREFERENCE){
        'SilentlyContinue'{
            # when silentlycontinue (default) is set, no message should apper
            $VerboseScriptBlock = "
            `$INHERITED_VERBOSE_PREFERENCE = '{0}'
            Write-Verbose -Message '{1}' -Verbose:`$false"
            $VerboseScriptBlock = $VerboseScriptBlock -f $INHERITED_VERBOSE_PREFERENCE,$VerboseMessage
        }
        'Continue'{
            # when continue is set, message should apper
            $VerboseScriptBlock = "
            `$INHERITED_VERBOSE_PREFERENCE = '{0}'
            Write-Verbose -Message '{1}' -Verbose:`$true"
            $VerboseScriptBlock = $VerboseScriptBlock -f $INHERITED_VERBOSE_PREFERENCE,$VerboseMessage
        }
        'Stop'{
            # when stop is set, the verbose command is treated as a terminating error, but the message will display
            $VerboseScriptBlock = "
            `$INHERITED_VERBOSE_PREFERENCE = '{0}'
            Write-Verbose -Message '{1}'"
            $VerboseScriptBlock = $VerboseScriptBlock -f $INHERITED_VERBOSE_PREFERENCE,$VerboseMessage
        }
        'Inquire'{
            # when inquire is set, the user will need to provide some input
            $VerboseScriptBlock = "
            `$INHERITED_VERBOSE_PREFERENCE = '{0}'
            Write-Verbose -Message '{1}'"
            $VerboseScriptBlock = $VerboseScriptBlock -f $INHERITED_VERBOSE_PREFERENCE,$VerboseMessage
        }
    }
    $scriptBlock = [scriptblock]::Create($VerboseScriptBlock)
    Invoke-Command -ScriptBlock $scriptBlock
}
Class Console {
    $Configuration = @{
        FilePath = "./Configuration/PSConsoleConfiguration.json"
    }
    $Properties = $this.GetConfiguration('All')
    $Switches = @{
        USE_INFO_BLOCK          = [bool]
        DEBUG_ON                = [bool]$false
        RESET_MESSAGE_TABLE     = [bool]$true
    }
    $Counters = @{
        TotalBlocks = [int]0
    }
    $MessageProperties = @{
        Message = [string]""
        Type = [string]
    }
    $MessageOrderTable = [ordered]@{}

    $BlockProperties = @{BlockName = [string]}
    $BlocksTable = [ordered]@{}
    $InfoBlockTable = [ordered]@{
    }
    $DecoratorTable = @{
        Type = @{
            Parent  = [string]"|-+"
            Process = [string]"  |"
            Final   = [string]"+-|"
        }
    }
    $Decorator = @{
        Current = @{
            Type = [string]
            Value = [string]
            Length = [int]
        }
        Previous = @{
            Type = $null
            Value = [string]
            Length = [int]
        }
    }
    $SubBufferBits          = [int]0
    $BufferBitsChar         = $this.Properties.TabCharacter
    $SubBufferBitsChar      = $this.Properties.TabCharacter
    $BufferString           = [string]
    $SubBufferString        = [string]
    $InfoBufferString       = [string]
    $BufferedMessage            = [string]
    $BufferedInfoBlockMessage   = [string]

    $ChecksTable = [ordered]@{
        SetBlock = [ordered]@{
            NotMutipleInputProperties = @{
                CHECK_PASSED = [bool]
                ErrorProperties = @{
                    WithStringReplace = $false
                    Message = "cant supply more than one property"
                }
            }
            ValidProperty = @{
                CHECK_PASSED = [bool]
                ErrorProperties = @{
                    WithStringReplace = $true
                    ReplaceWith = "Key"
                    Message = "{0} is not valid property that can be set"
                }
            }
            NotDuplicateBlockName = @{
                CHECK_PASSED = [bool]
                ErrorProperties = @{
                    WithStringReplace = $true
                    ReplaceWith = "BlockName"
                    Message = "{0} is already used by a block"
                }
            }
        }
        Verbose = [ordered]@{
            ValidProperty = @{
                CHECK_PASSED = [bool]$true
                ErrorProperties = @{
                    WithStringReplace = $true
                    ReplaceWith = "Type"
                    Message = "{0} is not valid property"
                }
            }
            NotNullInput = @{
                CHECK_PASSED = [bool]$true
                ErrorProperties = @{
                    WithStringReplace = $false
                    Message = "input for this method cannot be null"
                }
            }
            ParentInitialized = @{
                CHECK_PASSED = [bool]$false
                ErrorProperties = @{
                    WithStringReplace = $false
                    Message = "make sure the first message in your script is of type 'parent'"
                }
            }
        }
        GetActiveBlock = [ordered]@{
            BlockListIsEmpty = @{
                CHECK_PASSED = [bool]
                ErrorProperties = @{
                    WithStringReplace = $false
                    Message = "block list is empty"
                }
            }
        }
    }

    # get configuration item given a configurable property
    [psobject]GetConfiguration([string]$ConfigurationItem){
        $FilePath = $this.Configuration.FilePath
        $ConfigurationTable = Get-Content -Path $FilePath | ConvertFrom-Json -AsHashtable
        $ConfigurationTable = switch($ConfigurationItem){
            "All"{
                $ConfigurationTable
            }
            "PSConsole"{
                $ConfigurationTable.PSConsole
            }
            "TabCharacter"{
                $ConfigurationTable.TabCharacter
            }
            "WithLogging"{
                $ConfigurationTable.WithLogging
            }
            Default {}
        }
        return $ConfigurationTable
    }


    [void]SetConfiguration([bool]$USER_US_DEFAULT,[hashtable]$UserConfiguration){
        $FilePath = $this.Configuration.FilePath
        $USE_DEFAULT = $USER_US_DEFAULT

        # this is the default configuration
        $ConfigurationTableDefault = [ordered]@{
            PSConsole = @{
                On = 1
                Off = 0
            }
            TabCharacter = " "
            WithLogging = 0
        }

        $USE_USER_CONFIG = [bool]
        switch($USE_DEFAULT){
            $true{
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "User selected to use the default configuration" -Verbose
                }
                $ConfigurationTableNew =  $ConfigurationTableDefault | ConvertTo-Json
                Set-Content -Path $FilePath -Value $ConfigurationTableNew
                $USE_USER_CONFIG = $false
                $this.Properties = $this.GetConfiguration('All')
            }
            $false{
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "User selected to use a custom configuration" -Verbose
                }
                $USE_USER_CONFIG = $true
            }
        }

        # making sure user provided correct parameters
        $CHECK_PASSED = [bool]
        $commonItems = @()
        if($USE_USER_CONFIG){
            $commonItems = $ConfigurationTableDefault.keys | Where-Object { $_ -in $UserConfiguration.keys }
            if ($commonItems.Count -eq 0) {
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "'$($ConfigurationTableDefault.keys -join "','" )' were not supplied by the user." -Verbose
                }
                $CHECK_PASSED = $false
            }
            if($UserConfiguration.keys.Count -gt $ConfigurationTableDefault.Keys.Count){
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "More properties than required were supplied." -Verbose
                }
                $CHECK_PASSED = $false   
            }
            if(($commonItems.Count -gt 0) -and ($commonItems.count -lt $ConfigurationTableDefault.Keys.count)){
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "Only '$($UserConfiguration.keys -join "','" )' were supplied by the user." -Verbose
                }
                $CHECK_PASSED = $true   
            }
            if($UserConfiguration.Keys.Count -eq $ConfigurationTableDefault.Keys.Count){
                if($this.Switches.DEBUG_ON){
                    Write-Verbose -Message "All the properties where supplied." -Verbose
                }
                $CHECK_PASSED = $true  
            }

            if($CHECK_PASSED){
                $CURRENT_CONFIGURATION = $this.Properties
                foreach($item in $commonItems){
                    $NEW_VALUE = $UserConfiguration.$item
                    $CURRENT_CONFIGURATION.$Item =  $NEW_VALUE 
                }
                $ConfigurationTableNew = $CURRENT_CONFIGURATION | ConvertTo-Json
                Set-Content -path $FilePath -Value $ConfigurationTableNew
            }
            $this.Properties = $this.GetConfiguration('All')
        }
    }
    [void]SetDefaultConfiguration(){
        $this.SetConfiguration($true,@{})
        $this.Properties = $this.GetConfiguration('All')
        Write-Verbose -Message "Default configuration set." -Verbose
    }
    [void]SetTabCharacter([string]$TabCharacter){
        $isValidInput = [bool]
        if($TabCharacter.Length -lt 1){
            Write-Verbose -Message "The tab character cannot be an empty string." -Verbose
            $isValidInput = $false
        }
        if($TabCharacter.Length -gt 1){
            Write-Verbose -Message "The tab character cannot be of a length greater than 1." -Verbose
            $isValidInput = $false
        }
        if($TabCharacter.Length -eq 1){
            $isValidInput = $true
        }

        if($isValidInput){
            $this.SetConfiguration($false,@{
                TabCharacter = $TabCharacter
            })
            $this.Properties = $this.GetConfiguration('All')
            Write-Verbose -Message "'TabCharacter' updated to '$($TabCharacter)'." -Verbose
        }else{
            Write-Verbose -Message "'TabCharacter' was not updated." -Verbose
        }

    }
    [void]EnableLogging(){
        $loadPSLogging = [string]
        $isPSLoggingLoaded = [bool]
        $WithLoggingSetting = $this.GetConfiguration('WithLogging')
        if(-not(Get-Module -Name PSLogging)){
            Write-Verbose -Message "Note: Logging is a feature that requires the 'PSLogging' module to be loaded, would you like to load the module now?" -Verbose
            Do{
                $loadPSLogging = Read-Host "Type 'Y' to load PSLogging, or 'N' to not load it"
            }Until(@('Y','N','n','y') -contains $loadPSLogging)
            
            if(($loadPSLogging -eq 'Y') -or ($loadPSLogging -eq 'y')){
                # Need to work on the loading external module portion.
                $isPSLoggingLoaded = $false
            }else{
                $isPSLoggingLoaded = $false
            }
            if(($loadPSLogging -eq 'N') -or ($loadPSLogging -eq 'n')){
                $isPSLoggingLoaded = $false
            }
        }else{
            $isPSLoggingLoaded = $true
        }

        if($WithLoggingSetting -eq 0){
            if($isPSLoggingLoaded){
                $this.SetConfiguration($false,@{
                    WithLogging = 1
                })
                $this.Properties = $this.GetConfiguration('All')
                Write-Verbose -Message "Logging 'Enabled'." -Verbose
            }else{
                Write-Verbose -Message "Logging cannot be enabled until 'PSLogging' is loaded" -Verbose
            }
        }
        if($WithLoggingSetting -eq 1){
            Write-Verbose -Message "Logging is already 'Enabled'." -Verbose
        }
    }
    [void]DisableLogging(){
        $WithLoggingSetting = $this.GetConfiguration('WithLogging')
        if($WithLoggingSetting -eq 1){
            $this.SetConfiguration($false,@{
                WithLogging = 0
            })
            Write-Verbose -Message "Logging 'Disabled'." -Verbose
        }
        if($WithLoggingSetting -eq 0){
            Write-Verbose -Message "Logging is already 'Disabled'." -Verbose
        }
    }
    [void]EnablePSConsole(){
        $PSConsoleSetting = $this.GetConfiguration('PSConsole')
        $isEnabled = [bool]
        if(($PSConsoleSetting.Off -eq 0) -and ($PSConsoleSetting.On -eq 1)){
            $isEnabled = $true
        }else{
            $isEnabled = $false
        }

        if($isEnabled -eq $false){
            $this.SetConfiguration($false,@{
                PSConsole = @{
                    Off = 0
                    On = 1
                }
            })
            Write-Verbose -Message "PSConsole is 'Enabled'." -Verbose
        }else{
            Write-Verbose -Message "PSConsole is  already 'Enabled'." -Verbose
        }
    }
    [void]DisablePSConsole(){
        $PSConsoleSetting = $this.GetConfiguration('PSConsole')
        $isDisabled = [bool]
        if(($PSConsoleSetting.Off -eq 1) -and ($PSConsoleSetting.On -eq 0)){
            $isDisabled = $true
        }else{
            $isDisabled = $false
        }

        if($isDisabled -eq $false){
            $this.SetConfiguration($false,@{
                PSConsole = @{
                    Off = 1
                    On = 0
                }
            })
            $this.Properties = $this.GetConfiguration('All')
            Write-Verbose -Message "PSConsole is 'Disabled'." -Verbose
        }else{
            Write-Verbose -Message  "PSConsole is already 'Disabled'." -Verbose
        }
    }

    [void]Verbose([hashtable]$FromSender){
        $CHECK_PASSED = [bool]
        $CHECK_PASSED = $true

        # check user provided the needed parameters
        foreach($MSG_PROP in $FromSender.Keys){
            if($this.ChecksTable.Verbose.ValidProperty.CHECK_PASSED){
                if($this.MessageProperties.keys -contains $MSG_PROP){
                    $this.ChecksTable.Verbose.ValidProperty.CHECK_PASSED = $true
                }else{
                    $this.ChecksTable.Verbose.ValidProperty.CHECK_PASSED = $false
                    $CHECK_PASSED = $false
                }
            }
            else{
                $CHECK_PASSED = $false
            }
        }

        # check user provided input is not null
        if($CHECK_PASSED){
            foreach($MSG_PROP in $FromSender.Values){
                if($this.ChecksTable.Verbose.NotNullInput.CHECK_PASSED){
                    if($MSG_PROP.Length -gt 0){
                        $this.ChecksTable.Verbose.NotNullInput.CHECK_PASSED = $true
                        $CHECK_PASSED = $true
                    }else{
                        $this.ChecksTable.Verbose.NotNullInput.CHECK_PASSED = $false
                        $CHECK_PASSED = $false
                    }
                }
                else{
                    $CHECK_PASSED = $false
                }
            }
        }

        $ActiveBlock = $null
        if($CHECK_PASSED){
            # if this is the first block in the chain, the first type has to be a parent
            # so long as the total block count is 0 a new block will be created
            if($this.Counters.TotalBlocks -eq 0){
                if($FromSender.Type -eq "parent"){
                    # set block wasnt set by user, set default instead
                    $this.SetBlock(@{BlockName = "Block-$($this.Counters.TotalBlocks)"})
                }
            }else{
               
                # anytime you pass parent in a new block is generated
                if($FromSender.Type -eq "parent"){
                    if($this.ChecksTable.Verbose.ParentInitialized.CHECK_PASSED -eq $true){
                        $ActiveBlock = $this.GetActiveBlock()
                        $this.ChecksTable.Verbose.ParentInitialized.CHECK_PASSED = $false
                    }else{
                        $this.SetBlock(@{BlockName = "Block-$($this.Counters.TotalBlocks)"})
                    }
                   
                }else{
                    $ActiveBlock = $this.GetActiveBlock()
                    if($ActiveBlock -ne 0){
                        $CHECK_PASSED = $true
                    }else{
                        $CHECK_PASSED = $false
                    }
                    if($CHECK_PASSED){
                        if($FromSender.Type -match "process"){
                            $ActiveBlock.ProcessBlock.Count = $ActiveBlock.ProcessBlock.Count + 1
                            $ActiveBlock.ProcessBlock.MessagesList += $FromSender.Message
                        }
                        if($FromSender.Type -match "final"){
                            $ActiveBlock.FinalBlock.Count = $ActiveBlock.FinalBlock.Count + 1
                            $ActiveBlock.FinalBlock.MessagesList += $FromSender.Message
                        }
                        $this.BlocksTable.($ActiveBlock.BlockName) = $ActiveBlock
                    }
                }
            }
        }

        $this.InternalSetPreviousDecoratorProperties()

        $this.MessageProperties.Type = $FromSender.Type
        $this.InternalSetCurrentDecoratorProperties()
        $this.InternalSetInfoBlock()

        if($this.Switches.DEBUG_ON){Write-Verbose -Message "The current block count: $($this.Counters.TotalBlocks)." -Verbose}

        # this section handles how the output it tab'd for the various nested conditions
        if(($null -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Parent")){
            $this.SubBufferBits = $this.SubBufferBits - 0
        }
        if(("Parent" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Process")){
            $this.SubBufferBits = $this.SubBufferBits - 0
        }
        if(("Process" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Process")){
            $this.SubBufferBits = $this.SubBufferBits - 0
        }
        if(("Process" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Parent")){
            $this.SubBufferBits = $this.SubBufferBits + 2
        }
        if(("Process" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Final")){
            $this.SubBufferBits = $this.SubBufferBits - 0
        }
        if(("Final" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Final")){
            $this.SubBufferBits = $this.SubBufferBits - 2
            $this.InternalRemoveActiveBlock()
        }
        if(("Final" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Process")){
            $this.SubBufferBits = $this.SubBufferBits - 2
            $this.InternalRemoveActiveBlock()
        }
        if(("Parent" -eq $this.Decorator.Previous.Type) -and ($this.Decorator.Current.Type -eq "Parent")){
            $this.SubBufferBits = $this.SubBufferBits + 2
        }
       
        # handle the buffer being negative
        if($this.SubBufferBits -lt 0){
            $this.SubBufferBits = 0
        }

        # Here is where the message to output is constructed.
        $this.SubBufferString = ("$($this.SubBufferBitsChar)" * $this.SubBufferbits)
        $this.BufferString = ($this.Decorator.Current.Value).Replace(" ","$($this.BufferBitsChar)")
        $this.BufferedMessage = "{0}{1} '{2}'" -f ($this.SubBufferString),($this.BufferString),($FromSender.Message)

        if($this.Switches.RESET_MESSAGE_TABLE){
            $this.MessageOrderTable = [ordered]@{}
        }

        # Here is where the informational block ('BEGIN', 'END') are defined.
        if($this.Switches.USE_INFO_BLOCK){
            $this.InfoBufferString = ("$($this.BufferBitsChar)" * $this.Decorator.Current.Length)
            $this.BufferedInfoBlockMessage = "{0}{1} [{2}]{3}" -f ($this.SubBufferString),($this.InfoBufferString),($this.GetActiveBlock().BlockName),($this.InfoBlockTable.Type)
        }

        # The order for the informational portion of the message is set here.
        if($FromSender.Type -match "Parent"){
            $this.MessageOrderTable.Add("First",$this.BufferedInfoBlockMessage)
            $this.MessageOrderTable.Add("Second",$this.BufferedMessage)
        }
        if($FromSender.Type -match "Process"){
            $this.MessageOrderTable.Add("First",$this.BufferedMessage)
        }
        if($FromSender.Type -match "Final"){
            $this.MessageOrderTable.Add("First",$this.BufferedMessage)
            $this.MessageOrderTable.Add("Second",$this.BufferedInfoBlockMessage)
        }

        # Where the custom verbose string is displayed to the console.
        foreach($MessageID in $this.MessageOrderTable.keys){

            # If the user disabled PSConsole, then we default to vanilla verbose preferences.
            if($this.Properties.PSConsole.Off -eq 1){
                #Get-UDFVerbosePreferences -VerboseMessage $FromSender.Message -useGlobalVerbosePreferences:$true
                Write-Verbose -Message $FromSender.Message -Verbose
            }

            # Only when the user has 'PSConsole' enabled; does the formatted string get shown.
            if($this.Properties.PSConsole.Off -eq 0){
                # MessageID of 'First' defined the informational portion of the output.
                if($MessageID -eq "First"){
                    # While displaying the informational portion of the output is optional, its not a use controlled property.
                    if($this.Switches.USE_INFO_BLOCK){
                        #Get-UDFVerbosePreferences -VerboseMessage $this.MessageOrderTable.$MessageID -useGlobalVerbosePreferences:$true
                        Write-Verbose -Message $this.MessageOrderTable.$MessageID -Verbose
                    }else{
                        #Get-UDFVerbosePreferences -VerboseMessage $this.MessageOrderTable.$MessageID -useGlobalVerbosePreferences:$true
                        Write-Verbose -Message $this.MessageOrderTable.$MessageID -Verbose
                    }
                }
                # MessageID of 'Second' defines the message itself, its always second.
                if($MessageID -eq "Second"){
                    #Get-UDFVerbosePreferences -VerboseMessage $this.MessageOrderTable.$MessageID -useGlobalVerbosePreferences:$true
                    Write-Verbose -Message $this.MessageOrderTable.$MessageID -Verbose
                }
            }
        }

        # For compatability reasons, check to make sure the PSLogging module is loaded.
        # if(Get-Module -Name "PSLogging"){
        #     $loggedMsg = [string]
        #     if($this.Properties.WithLoging -eq 1){
        #       $loggedMsg =  "{0} - {1}" -f ($this.GetActiveBlock().BlockName),($FromSender.Message)
        #       #test-logging -Message $loggedMsg
        #     }
        # }
        # if the PSLogging module is not loaded, and logging is enabled. nothing will happen
    }

    [void]SetBlock([hashtable]$FromSender){
        $CONTINUE_CHECKS = [bool]
        # check user is not providing more than 1 property
        if(-not($FromSender.Keys.Count -gt 1)){
            $this.ChecksTable.SetBlock.NotMutipleInputProperties.Check_PASSED = $true
            $CONTINUE_CHECKS = $true
        }else{
            $this.ChecksTable.SetBlock.NotMutipleInputProperties.Check_PASSED = $false
            $CONTINUE_CHECKS = $false
        }

        # check user is providing a proper property to set
        if($CONTINUE_CHECKS -eq $true){
            if($this.ChecksTable.SetBlock.NotMutipleInputProperties.Check_PASSED){
                if(($this.BlockProperties.keys) -contains ($FromSender.Keys)){
                    $this.ChecksTable.SetBlock.ValidProperty.CHECK_PASSED = $true
                    $CONTINUE_CHECKS = $true
                }else{
                    $this.ChecksTable.SetBlock.ValidProperty.CHECK_PASSED = $false
                    $CONTINUE_CHECKS = $false
                }
            }
        }
        if($CONTINUE_CHECKS -eq $true){
            if($this.ChecksTable.SetBlock.ValidProperty.CHECK_PASSED){
                if($this.BlocksTable.Keys -notcontains $FromSender.Values){
                    $this.BlocksTable.Add("$($FromSender.Values)", [ordered]@{
                        ProcessBlock    = @{
                            Count           = [int]0
                            MessagesList    = @()
                        }
                        FinalBlock      = @{
                            Count           = [int]0
                            MessagesList    = @()
                        }
                        BlockName           = [string]$FromSender.Values
                        BlockisActive       = [bool]
                    })
                    $this.Counters.TotalBlocks = $this.Counters.TotalBlocks + 1
                    $this.ChecksTable.SetBlock.NotDuplicateBlockName.CHECK_PASSED = $true
                    $CONTINUE_CHECKS = $true
                }else{
                    $this.ChecksTable.SetBlock.NotDuplicateBlockName.CHECK_PASSED = $false
                    $CONTINUE_CHECKS = $false
                }
            }
        }
        $this.ChecksTable.Verbose.ParentInitialized.CHECK_PASSED = $true
        # as blocks get added, the only the active one is the current one, all others
        # get set as inactive
        if($CONTINUE_CHECKS){
            $this.InternalSetBlockActiveState("$($FromSender.BlockName)")
          
        }

        $CHECK_GROUP = "SetBlock"
        if($this.Switches.DEBUG_ON){
            Write-Verbose -Message "[DEBUG_ON]`n----------------" -Verbose
        }
        # checks get reset at the end of the setblock operation
        foreach($CHECK_NAME in $this.ChecksTable.$CHECK_GROUP.Keys){
            $CHECK_PASSED = $this.ChecksTable.$CHECK_GROUP.$CHECK_NAME.CHECK_PASSED

            #region begin DEBUG
            if($this.Switches.DEBUG_ON){
                Write-Verbose -Message $("'$CHECK_NAME':'$CHECK_PASSED'") -Verbose
            }
            #endregion

            # reset the check_passed values
            $this.ChecksTable.$CHECK_GROUP.$CHECK_NAME.CHECK_PASSED = [bool]
        }
    }

    [void]InternalSetBlockActiveState([string]$FromSender){
        foreach($block in $this.BlocksTable.keys){
            if($block -notmatch $FromSender){
                $this.BlocksTable.$block.BlockisActive = $false
            }
            if($block -match $FromSender){
                $this.BlocksTable.$block.BlockisActive = $true
            }
        }
    }

    [void]InternalRemoveActiveBlock(){
        if($this.Counters.TotalBlocks -ne 0){
            $LastBlocks = ($this.BlocksTable.Keys) | Select-Object -Last 2
            $InActiveBlock = $LastBlocks | Select-Object -First 1
            $ActiveBlock = $LastBlocks | Select-Object -Last 1
            $this.BlocksTable.Remove($ActiveBlock)
            $this.InternalSetBlockActiveState($InActiveBlock)
            $this.Counters.TotalBlocks = $this.Counters.TotalBlocks - 1
        }
    }

    [psobject]GetActiveBlock(){
        $CHECK_PASSED = [bool]
        if($this.Counters.TotalBlocks -lt 1){
            $this.ChecksTable.GetActiveBlock.BlockListIsEmpty.CHECK_PASSED = $false
            $CHECK_PASSED = $false
        }else{
            $CHECK_PASSED = $true
        }
        if($CHECK_PASSED){
            $BlockName = ($this.BlocksTable.Keys) | Select-Object -Last 1
            return $this.BlocksTable.$BlockName
        }else{
            return 0
        }
    }

    [void]InternalSetCurrentDecoratorProperties(){
        switch($this.MessageProperties.Type){
            "Parent" {
                $this.Decorator.Current.Type = "Parent"
                $this.Decorator.Current.Value = $this.DecoratorTable.Type.Parent
                $this.Decorator.Current.Length = ($this.Decorator.Current.Value).Length
            }
            "Process" {
                $this.Decorator.Current.Type = "Process"
                $this.Decorator.Current.Value = $this.DecoratorTable.Type.Process
                $this.Decorator.Current.Length = ($this.Decorator.Current.Value).Length
            }
            "Final" {
                $this.Decorator.Current.Type = "Final"
                $this.Decorator.Current.Value = $this.DecoratorTable.Type.Final
                $this.Decorator.Current.Length = ($this.Decorator.Current.Value).Length
            }
        }
    }

    [void]InternalSetPreviousDecoratorProperties(){
        $this.Decorator.Previous.Type = $this.Decorator.Current.Type
        $this.Decorator.Previous.Value = $this.Decorator.Current.Value
        $this.Decorator.Previous.Length = ($this.Decorator.Previous.Value).Length
    }

    [void]InternalSetInfoBlock(){
        $this.Switches.USE_INFO_BLOCK = switch($this.MessageProperties.Type){
            "Parent" {
                $this.InfoBlockTable.Type = "[BEGIN]"
                $true
            }
            "Process" {
                $this.InfoBlockTable.Type = "[PROCESS]"
                $false
            }
            "Final" {
                $this.InfoBlockTable.Type = "[END]"
                $true
            }
        }
    }
}
$test = [console]::new()

# for testing purposes, set DEBUG_ON = $true
$test.Switches.DEBUG_ON = $false 

# Public commands to get and set configuration.
$test.DisablePSConsole()
$test.EnablePSConsole()
$test.SetDefaultConfiguration()
$test.EnableLogging()
$test.DisableLogging()
$test.SetTabCharacter('.')

# Private internal commands used by the module, use the public available commands for user related tasks.
$test.GetConfiguration("All")
$test.GetConfiguration("PSConsole")
$test.GetConfiguration("TabCharacter")
$test.GetConfiguration("WithLogging")
$test.SetConfiguration($true,@{})
$test.SetConfiguration($false,@{
    WithLogging = 0
})
$test.SetConfiguration($false,@{
    TabCharacter = '.'
    WithLogging = 0
})

# Testing 'PSConsole'

function test-that {
    $test.SetBlock(@{BlockName = "ThisTest"})
    $test.Verbose(@{Message = "subparent"; Type = "parent"})
    $test.Verbose(@{Message = "test-that"; Type = "Process"})
    $test.Verbose(@{Message = "test-that"; Type = "Process"})
    $test.Verbose(@{Message = "test-that"; Type = "final"})
}

function test-other {
    $test.SetBlock(@{BlockName = "Test2"})
    $test.Verbose(@{Message = "sub parent"; Type = "parent"})
    test-that
    $test.Verbose(@{Message = "sub process"; Type = "Process"})
    $test.Verbose(@{Message = "sub final"; Type = "final"})
}

function test-this {
    $test.Verbose(@{Message = "top-proc parent"; Type = "parent"})
    $test.Verbose(@{Message = "top process"; Type = "Process"})
    test-other
    $test.Verbose(@{Message = "this is something enw"; Type = "Process"})
    $test.Verbose(@{Message = "top final"; Type = "final"})
}

# we dont want to have to change the verbose preference at the profile level
$VerbosePreference = 'Continue'
$VerbosePreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Inquire'




# stop test
# Write a verbose message
function test-verbose{
    Write-Verbose "This is a verbose message."

    # The script will stop here after displaying the verbose message
    Write-Host "This line will not be executed."
    Write-Host "This line will not be executed2."
}
