class VerboseMessage{
    $UserVerbosePreference = $VerbosePreference
    $Options = @{
        EnableMyVerbose = $true
    }
    $Padding = @{
        By = 0
        Symbole = " "
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
        Parent  = "-+"
        Nested  = "|++"
        Process = "|-+"
        Final   = "+-|"
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


        $WriteVerboseParams.Message = " in the subprocess"
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


        $WriteVerboseParams.Message = " in in the parent, but im the first subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)

        $WriteVerboseParams.Message = " in in the parent, but im the second subprocess"
        $WriteVerboseParams.MsgType = "Process"
        $this.WriteVerbose($WriteVerboseParams)


        #$this.Padding.By = $this.Padding.By -2
        $this.Test2()

        #$this.Padding.By = $this.Padding.By -2
        $WriteVerboseParams.Message = " in the final subprocess of my parent"
        $WriteVerboseParams.MsgType = "Process"
        $WriteVerboseParams.isFinal = $true
        $this.WriteVerbose($WriteVerboseParams)
        $this.ResetVerbose($WriteVerboseParams)
    }
    [void]ResetVerbose([hashtable]$fromSender){

        if($null -eq $this.ImTheParent.Name){
            #write-host "no one has called dibs on parent"
            $this.ImTheParent.Name = $fromSender.CallerName
        }
        else{
            #Write-host "only the parent gets to reset the bit"
            if(($fromSender.CallerName) -match ($this.ImTheParent.Name)){
                $this.ImTheParent.bit = 0
            }else{
                #write-host "the caller $($fromSender.CallerName) not =  $($this.ImTheParent.Name), cant reset bit"
            }
        }
    }
    [void]WriteVerbose($fromSender){
        $offsetBy = "VERBOSE: ".Length
        $verboseOptionValue = [string]
        $decorator = [string]
        if(($this.Options.EnableMyVerbose) -eq $false){
            #write-host "opting to not use the custom verbose feature"
            #write-host "will inherit the verbose options from your session.."

            if($this.UserVerbosePreference -eq 'continue'){
                #write-host "you have verbose option set to continue"
                $verboseOptionValue = $true

            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }
            #Write-Verbose -Message $fromSender.Message -Verbose:$verboseOptionValue
        }
         # here is where the custom magic happens, assuming you the have verboseoption enabled
        else{
            #write-host "opting to use the custom verbose feature"
            if($this.UserVerbosePreference -eq 'continue'){
                #write-host "you have verbose option set to continue"
                $verboseOptionValue = $true

            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }
            
            $decorator = switch($this.ImTheParent.bit){
                0 {
                    $this.ImTheParent.Name = $fromSender.CallerName
                    $this.ImTheParent.bit = 1
                    $this.Decorators.Parent
                    $this.Tracker.LastDecorator = ' '
                    break
                }

                1 {
                    #write-host 'something already called parent dibs'
                    if(($fromSender.MsgType) -match "Parent"){
                        $this.Decorators.Nested
                        #$this.Padding.By = $this.Padding.By + 2
                        break
                    }
                    if(($fromSender.MsgType) -match "Process"){
                        #$this.WhosTheParent(@{Name = ($fromSender.CallerName)})
                        $this.Decorators.Process
                        break
                    }
                    break
                }
            }
            if($fromSender.MsgType -ne "Process"){
                $this.Padding.String = $($this.Padding.Symbole) * ($this.Padding.By)
            }else {
                $this.Padding.String = $($this.Padding.Symbole) * ($this.Padding.By)
            }
           
            $this.Tracker.LastDecorator = $decorator
            if($fromSender.isFinal){
                $myMsg = "{0}{1}{2}" -f ($this.Padding.String),$decorator,"$($fromSender.Message)`n"
                $this.Padding.By = $this.Padding.By - (($this.Tracker.LastDecorator).length -1)
                $myMsg = "$($myMsg)$(' ' * $offsetby)$($($this.Padding.Symbole) * ($this.Padding.By))$($this.Decorators.Final)"
            }else{
                $this.Padding.By = $this.Padding.By + (($this.Tracker.LastDecorator).length -1)
                $offsetBy = 0
                $myMsg = "{0}{1}{2}" -f ($this.Padding.String),$decorator,$fromSender.Message
            }
            
            #$myMsg = '{0}{1}{2}' -f ($this.Padding.String),$decorator,$fromSender.Message
            Write-Verbose -Message $myMsg -Verbose:$verboseOptionValue
            

        }
    }
}


$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

$Verbose = [VerboseMessage]::new()
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
<#
-+| Getting Config
..|--+ Doing Something
..|--+ Doing something else
..+-+| Loading Config
.....|--+ Doing something
.....|--+ doing something else
..|--+ back to config
..|--+ done

#>
