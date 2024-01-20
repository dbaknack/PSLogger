# Initalize an instance of the class
$Console = [Console]::new()

# By default DEBUG_ON is set to false, switch to true, if you need to troubleshoot something
#$Console.Switches.DEBUG_ON = $true

# this switch is used to reset the message table containing the ordered messages to display
$Console.Switches.RESET_MESSAGE_TABLE

# Switch is used to control what message types will display the info block along side the message
$Console.Switches.USE_INFO_BLOCK

# Used to track how many messages have been added to the buffer
$Console.Counters.TotalBlocks

# Key-Value table containing the message, and the type of message
$Console.MessageProperties

# Null initally, but will contain the messages and info blocks to the console
$Console.MessageOrderTable

# Key-value table containing the definitions of the block properties
$Console.BlockProperties

# Null initally, but will contain a running list of block entries, and their associated properties
$Console.BlocksTable

# Null initally, but will contain info block properties 
$Console.InfoBlockTable

# Table for the decorator value, length, and type
$Console.Decorator.Current
$Console.Decorator.Previous

# Key-value table for the decorators used in the output messages
$Console.DecoratorTable.Type.Final
$Console.DecoratorTable.Type.Parent
$Console.DecoratorTable.Type.Process


# used to track the checks at runtime
$Console.ChecksTable
$Console.ChecksTable.Verbose.ParentInitialized

# use this to check the running counts of blocks
$Console.Counters.TotalBlocks


# use this to check a given parent block process entries
$Console.BlocksTable."Block-0".ProcessBlock.MessagesList
$Console.GetActiveBlock()
if(($Console.BlocksTable)){
    'this'
}
# here as some exmples of usage
$Console.SetBlock(@{BlockName = "Test"})
$Console.Verbose(@{Message = "test-that";Type    = "parent"})
$Console.Verbose(@{Message = "test-that"; Type = "Process"})
$Console.Verbose(@{Message = "test-thdat"; Type = "Process"})
$Console.Verbose(@{Message = "test-that"; Type = "final"})
function test-that {
    $Console.SetBlock(@{BlockName = "ThisTest"})
    $Console.Verbose(@{Message = "sub parent"; Type = "parent"})
    $Console.Verbose(@{Message = "test-that"; Type = "Process"})
    $Console.Verbose(@{Message = "test-that"; Type = "Process"})
    $Console.Verbose(@{Message = "test-that"; Type = "final"})
}

function test-other {
    $Console.SetBlock(@{BlockName = "Test2"})
    $Console.Verbose(@{Message = "sub parent"; Type = "parent"})
    test-that
    $Console.Verbose(@{Message = "sub process"; Type = "Process"})
    $Console.Verbose(@{Message = "sub final"; Type = "final"})
}

function test-this {
    $Console.Verbose(@{Message = "top-proc parent"; Type = "parent"})
    $Console.Verbose(@{Message = "top process"; Type = "Process"})
    test-other
    $Console.Verbose(@{Message = "this is something enw"; Type = "Process"})
    $Console.Verbose(@{Message = "top final"; Type = "final"})

}
$Console.SetTabCharacter('.')
$Console.properties.WithLoging = $true
test-this
$Console.InternalRemoveActiveBlock()
