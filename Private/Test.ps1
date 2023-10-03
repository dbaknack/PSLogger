class VerboseMessage{
    $UserVerbosePreference = $VerbosePreference
    $Options = @{
        EnableMyVerbose = $true
    }
    $Padding = @{
        Symbole = "."
    }
    $PaddingIndex = 0
    $CallingNestedParent = $false
    $Decorators = @{
        Leading = @{
            Parent = "-+| "
            Nested = "+-+| "
        }
        Process  = "|--+ "

    }

    [void]WriteVerbose($fromSender){
        $verboseOptionValue = [string]
 
        if(($this.Options.EnableMyVerbose) -eq $false){
            write-host "opting to not use the custom verbose feature"
            write-host "will inherit the verbose options from your session.."
            if($this.UserVerbosePreference -eq 'continue'){
                write-host "you have verbose option set to continue"
                $verboseOptionValue = $true
            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }
            Write-Verbose -Message "using regular verbose" -Verbose:$verboseOptionValue
        }else{
            write-host "opting to use the custom verbose feature"
            if($this.UserVerbosePreference -eq 'continue'){
                write-host "you have verbose option set to continue"
                $verboseOptionValue = $true
            }elseif($this.UserVerbosePreference -eq 'SilentlyContinue'){
                $verboseOptionValue = $false
            }
            Write-Verbose -Message "using customer verbose" -Verbose:$verboseOptionValue
        }
    }
}

$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'
$Verbose = [VerboseMessage]::new()
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