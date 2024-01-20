class VerboseMessage{
    $UserVerbosePreference = $VerbosePreference
    $Options = @{
        EnableMyVerbose = $true
    }
    $Padding = @{
        By = 0
        Symbole = "."
        String = [string]
    }
    $Tracker =@{
        LastDecorator = ''
    }
    $ImTheParent = @{
        bit     = [int]0
        Name    = $null
    }
    $Decorators = @{
        Parent  = "|-+"
        Process = "|"
        Final   = "+-|"
    }
    [void]Test4(){
        $methodName = "Test4"
        $WriteVerboseParams = @{
            Message = [string]
            MsgType = [string]
            isFinal = $false
            CallerName = $methodName
        }
        
        $WriteVerboseParams.Message =" $methodName"
        $WriteVerboseParams.MsgType = "Parent"
        $this.WriteVerbose($WriteVerboseParams)
Write-Verbose -Message "test" -Verbose

        $WriteVerboseParams.Message = " im the first subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " im the seconds subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " im the last subprocess, this is the final message"
        $WriteVerboseParams.MsgType = "Process"
        $WriteVerboseParams.isFinal = $true
        $this.WriteVerbose($WriteVerboseParams)

        $this.ResetVerbose($WriteVerboseParams)
    }
    [void]Test3(){
        $methodName = "Test3"
        $WriteVerboseParams = @{
            Message = [string]
            MsgType = [string]
            isFinal = $false
            CallerName = $methodName
        }
        
        $WriteVerboseParams.Message =" $methodName"
        $WriteVerboseParams.MsgType = "Parent"
        $this.WriteVerbose($WriteVerboseParams)

        $this.Test4()
        $WriteVerboseParams.Message = " im the first subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " im the seconds subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " in the subprocess, this is the final message"
        $WriteVerboseParams.MsgType = "Process"
        $WriteVerboseParams.isFinal = $true
        $this.WriteVerbose($WriteVerboseParams)

        $this.ResetVerbose($WriteVerboseParams)
    }
    [void]Test2(){
        $methodName = "Test2"
        $WriteVerboseParams = @{
            Message = [string]
            MsgType = [string]
            isFinal = $false
            CallerName = $methodName
        }
        
        $WriteVerboseParams.Message =" $methodName"
        $WriteVerboseParams.MsgType = "Parent"
        $this.WriteVerbose($WriteVerboseParams)


        $WriteVerboseParams.Message = " im the first subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $this.Test3()
        $WriteVerboseParams.Message = " im the seconds subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " in the subprocess, this is the final message"
        $WriteVerboseParams.MsgType = "Process"
        $WriteVerboseParams.isFinal = $true
        $this.WriteVerbose($WriteVerboseParams)
        $this.ResetVerbose($WriteVerboseParams)
    }
    [void]Test1(){
        $methodName = "Test1"
        $WriteVerboseParams = @{
            Message = [string]
            MsgType = [string]
            isFinal = $false
            CallerName = $methodName
        }


        $WriteVerboseParams.Message = " $methodName"
        $WriteVerboseParams.MsgType = "Parent"
        $this.WriteVerbose($WriteVerboseParams)


        $WriteVerboseParams.Message = " im in the parent, but im the first subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " im in the parent, but im the second subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)


        $this.Test2()
        $this.Test3()

        $WriteVerboseParams.Message = " in the final subprocess of my parent"
        $WriteVerboseParams.MsgType = "Process"
        $WriteVerboseParams.isFinal = $true
        $this.WriteVerbose($WriteVerboseParams)
        $this.ResetVerbose($WriteVerboseParams)
    }
    [void]ResetVerbose([hashtable]$fromSender){
       #write-host "$($this.ImTheParent.Name) - $($fromSender.CallerName) : $($this.ImTheParent.bit) - $($this.Padding.By)" -ForegroundColor Green
       # write-host "reseting" -ForegroundColor cyan
        $this.ImTheParent.bit = 0
    }
    [void]WriteVerbose($fromSender){
        $MyMsgRaw = $fromSender.Message

        Write-Host "Step 1.0) Initializing" -ForegroundColor Cyan
        $offsetByLength = ("VERBOSE: ".Length)
        Write-Host "`$offsetBy = $offsetByLength" -ForegroundColor Cyan

        $callerName = $fromSender.CallerName
        $paddingBy = $this.Padding.By
        $padWithString = $this.Padding.String
        $isEnableMyVerbose = $this.Options.EnableMyVerbose
        $paddingSymbole = $this.Padding.Symbole
        $verboseOptionValue = [bool]
        $decorator = [string]

        
        if(($isEnableMyVerbose) -eq $false){
            if($this.UserVerbosePreference -eq 'continue'){
                $verboseOptionValue = $true
            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }
        }else{
            if($this.UserVerbosePreference -eq 'continue'){
                $verboseOptionValue = $true
            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }

            # select the decorator to use
            $Decorator = switch($this.ImTheParent.bit){
                0 {
                    Write-Host "Step 2.0) The Parent Bit is set to 1 when first initalized" -ForegroundColor Cyan
                    $this.ImTheParent.Name = $callerName
                    $this.ImTheParent.bit = 1
                    $this.Decorators.Parent
                    break
                }
                1 {
                    if($fromSender.isFinal -eq $true){
                        Write-Host "Step 2.3) This is the final message of the stack" -ForegroundColor cyan
                        $this.Decorators.Final
                    }else{
                        if(($fromSender.MsgType) -match "Process"){
                            Write-Host "Step 2.1) The msgtype is process and the parent bit is 1, the parent decorator is used" -ForegroundColor Cyan
                            $this.Decorators.Process
                            break
                        }
                        break
                    }
                }
            }
            $this.Padding.String = ($paddingSymbole * $paddingBy)
            $padWithString = $this.Padding.String
            $this.Tracker.LastDecorator = $Decorator
        }
        # padding, decorator, and message
        $MY_MESSAGE = "{0}{1}{2}" -f $padWithString,$Decorator,$MyMsgRaw
        Write-Verbose -Message $MY_MESSAGE -Verbose:$verboseOptionValue
    }
}

$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

$Verbose.Padding.Symbole = " "
$Verbose = [VerboseMessage]::new()
$Verbose.Test3() 
$Verbose.Test4()
$Verbose.Test1()
$Verbose.Test2()
$Verbose.WriteVerbose(@{
    Message = 'this is my message'
    MsgType = 'Parent'
})
$Verbose.WriteVerbose(@{
    Message = 'this is my message'
    MsgType = 'Nested'
})
$Verbose.WriteVerbose(@{
    Message = 'this is my message'
    MsgType = 'Process'
})



# set to false if you dont want to use the custom verbose feature
$Verbose.Options.EnableMyVerbose = $false
$Verbose.Options.EnableMyVerbose = $true

$Verbose.WriteVerbose(@{Message = "hi"})

$Verbose.CallingNestedParent


#|-+[parent]
#..|[process]
#..|[process]
#..|-+[nested]
#....|[process]
#....|[process]
#..+-|[DONE]
#..|[Process]
#..|[DONE]