# Genesis

Generic preprocessor for modern programming languages.

## Features

* Language agnostic.
* Complete : multi-token variables and functions, local and global scopes, inclusions, imports, expressions, assignments, conditions, loops, function calls, etc.
* Emulates genericity by parametric template instantiation.
* Allows Allman style for Go code.

## Command line

genesis [options] {input_extension} {output_extension}

### Options
``` 
    --input_filter * : only include files with names matching this filter (anything by default)
    --input_folder . : input folder (current folder by default)
    --output_folder = : output folder (same as input_folder by default)
    --recursive : also process sub folders
    --join_lines : join source code lines written in Allman style
    --verbose : show the processing messages
    --debug : show the debugging messages
    --fatal : abort execution in case of an error
``` 
### Examples

Read all ".jp" files in the current directory, and convert them into preprocessed ".js" files.

```bash
genesis .jp .js
```

Recursively read all ".gp" files in the current directory, and convert them into preprocessed ".go" files with joined lines.

```bash
genesis --recursive --join_lines .gp .go
```

## Features

### Variables 

Variables are replaced inside strings and comments, but not inside identifiers, 
unless they are surrounded by "@" characters or defined with a '#set*' directive.
    
```cpp
// test.gp

#set XXX = BLABLA
#set* YYY = BLABLA

XXX "MY XXX NAME" MYXXXNAME MY@XXX@NAME    // XXX
YYY "MY YYY NAME" MYYYYNAME MY@YYY@NAME    // YYY

// test.go

BLABLA "MY BLABLA NAME" MYXXXNAME MYBLABLANAME    // BLABLA
BLABLA "MY BLABLA NAME" MYBLABLANAME MYBLABLANAME    // BLABLA
```

### Parametric definitions

```cpp
#define! MakeStack
    #get _ELEMENT_
    
    #set _ELEMENT_STACK_ = @_Element_@_STACK
    #set _Element_ := "_ELEMENT_".toPascalCase()
    #set _ElementArray_ = @_Element_@Array
    
    type _ELEMENT_STACK_ struct
    {
        _ElementArray_ [] * _Element_;
    }
    
    func ( self * _ELEMENT_STACK_ ) Push@_Element_@(
        element * _Element_
        )
    {
        _ElementArray_ = append( _ElementArray_, element )
    }
    
    func ( self * _ELEMENT_STACK_ ) Pop@_Element_@(
        ) * _ELEMENT_
    {
        var element * _ELEMENT_;
        
        element = _ElementArray_[ len( _ElementArray_ ) - 1 ];
        
        _ElementArray_ = _ElementArray_[ : len( _ElementArray_ ) - 1 ];
        
        return element; 
    }
    
    #set! STACK[ _Element_ ] @= _ELEMENT_STACK_
#end

#call MakeStack, ENTITY

var entity_stack STACK[ ENTITY ];
...
stack.PushEntity( entity );
```

### Parametric inclusions

```cpp
// stack.gpp

#get _ELEMENT_

#set _ELEMENT_STACK_ = @_Element_@_STACK
#set _Element_ ?= "_ELEMENT_".toPascalCase()
#set _ElementArray_ = @_Element_@Array

type _ELEMENT_STACK_ struct
{
    _ElementArray_ [] * _Element_;
}

func ( self * _ELEMENT_STACK_ ) Push@_Element_@(
    element * _Element_
    )
{
    _ElementArray_ = append( _ElementArray_, element )
}

func ( self * _ELEMENT_STACK_ ) Pop@_Element_@(
    ) * _ELEMENT_
{
    var element * _ELEMENT_;
    
    element = _ElementArray_[ len( _ElementArray_ ) - 1 ];
    
    _ElementArray_ = _ElementArray_[ : len( _ElementArray_ ) - 1 ];
    
    return element; 
}

#set! STACK[ _Element_ ] @= _ELEMENT_STACK_

// main.gp

#include stack.gpp, ENTITY
...
var entity_stack STACK[ ENTITY ];
...
entity_stack.PushElement( entity );

```

### Conditions

```cpp
#set PLATFORM = "linux"

#if PLATFORM == "linux"
    ...
#elseif PLATFORM == "windows"
    ...
#elseif PLATFORM == "macos"
    ...
#elseif PLATFORM == "ios"
    ...
#elseif PLATFORM == "android"
    ...
#else
    #error Unknown platform : PLATFORM
#end
```

### Loops

```cpp
#set INDEX = 0
#set SUM = 0

#while INDEX < 10
    #set INDEX := INDEX + 1
    #set SUM := SUM + INDEX
    #print INDEX
    #print SUM
    INDEX : SUM
#end

#print INDEX
#print SUM
```
    
### Allman style conversion

```go
func GetResult(
    first_integer int,
    second_integer int,
    third_integer int,
    fourth_integer int
    ) ( result int )
{
    if first_integer == second_integer
       || ( first_integer < second_integer
            && first_integer > 10
            && second_integer < 20 )
       || ( first_integer > second_integer
            && first_integer > 10
            && second_integer < 20 )
    {
        result
            = GetResult(
                  first_integer * second_integer,
                  second_integer * third_integer,
                  third_integer * fourth_integer,
                  fourth_integer * first_integer
                  );
    }
    else
    {
        result = 0;
    }
    
    return;
}

func GetResult( first_integer int, second_integer int, third_integer int, fourth_integer int ) ( result int ) {
    if first_integer == second_integer || ( first_integer < second_integer && first_integer > 10 && second_integer < 20 ) || ( first_integer > second_integer && first_integer > 10 && second_integer < 20 ) {
        result = GetResult( first_integer * second_integer, second_integer * third_integer, third_integer * fourth_integer, fourth_integer * first_integer );
    } else {
        result = 0;
    }

    return;
}
```

## Syntax

### Command modifiers

Some commands can be suffixed with one or several modifiers, in the following order.

```
* : the variable is replaced inside identifiers
! : the variable or function is defined globally
```

### Assignment modifiers

The assignment operator (=) can be prefixed with one or several modifiers, in the following order.

```
@ : replace variables by their values also in the variable name
$ : quote the variable value
: : evaluate the variable definition as a constant expression
# : don't replace variables by their value in the variable definition
```

### Directives

#### \#define[!] function

Declares a parametric function.
    
```cpp
#define MY_GLOBAL_FUNCTION
    #get _FIRST_NAME_
    #get _LAST_NAME_
    Hello _FIRST_NAME_ _LAST_NAME_
#end

#define~ MY_LOCAL_FUNCTION
    #get _FIRST_NAME_
    #get _LAST_NAME_
    Hello _FIRST_NAME_ _LAST_NAME_
#end
```

#### \#undefine[!] function

Undeclares a parametric function.
    
```cpp
#undefine MY_GLOBAL_FUNCTION
#undefine~ MY_LOCAL_FUNCTION
```

#### \#call function \[ , first_argument, second_argument, ... \] 

Calls a function.
    
```cpp
#call MY_GLOBAL_FUNCTION, John, Doe
#call MY_LOCAL_FUNCTION, John, Doe
```

#### \#include file_path \[ , first_argument, second_argument, ... \] 

Includes a parametric file.
    
```cpp
#include file.gpp, Type, "Text", 10
```
    
#### \#import file_path \[ , first_argument, second_argument, ... \]
    
Includes a parametric file only once.
    
```cpp
#import file.gpp, Type, "Text", 10
```

#### \#insert file_path
    
Includes an unprocessed file.
    
```cpp
#insert file.txt
```

#### \#get[*!] local_variable

Assigns a call or inclusion argument to a variable.

```cpp
// file.gpp

#get FIRST_ARGUMENT
#get SECOND_ARGUMENT
#get THIRD_ARGUMENT

FIRST_ARGUMENT    // Type
SECOND_ARGUMENT    // "Text"
THIRD_ARGUMENT    // 10
```

#### \#set[*!] variable [@$:#]= definition

Assigns a definition to a variable.

Local variables and definitions are available only until the end of the file that defines them,
and are replaced before global variables and definitions.
    
```cpp
#set! GLOBAL_VARIABLE = The definition of a global variable
#set LOCAL_VARIABLE = The definition of a local variable
#set EVALUATED_VARIABLE := "GLOBAL_VARIABLE".toUpperCase() + "LOCAL_VARIABLE".toLowerCase()
#set* REPLACED_VARIABLE = The definition of a local variable replaced inside identifiers
#set VARIABLE_NAME = QUOTED_UNREPLACED_VARIABLE
#set VARIABLE_NAME @$#= GLOBAL_VARIABLE is not replaced here

GLOBAL_VARIABLE
LOCAL_VARIABLE
EVALUATED_VARIABLE
NICE_REPLACED_VARIABLE_HERE
QUOTED_UNREPLACED_VARIABLE
```

#### \#unset[*!] variable

Removes a variable.
        
```cpp
#unset! MY_GLOBAL_VARIABLE
#unset MY_LOCAL_VARIABLE
```

#### \#if boolean_expression | #ifset variable | #ifnotset variable | #ifdefined function | #ifnotdefined function<br/>\#elseif boolean_expression<br/>\#else<br/>\#end

Executes a conditional block.

```cpp
#if SECOND_ARGUMENT + THIRD_ARGUMENT == "Text10"
    ...
#elseif "FIRST_ARGUMENT" == "Type"
    ...
#elseif SECOND_ARGUMENT == "Text"
    ...
    #ifdefined SOME_OPTION
        ...
    #else
        ...
    #end
    ...
#elseif THIRD_ARGUMENT == 10
    ...
#else
    ...
#end
```

#### \#while boolean_expression<br/>\#end
  
Repeats a conditional block
  
```cpp
#set FACTOR = 3
#set COUNT = 10
#set INDEX = 0

#while INDEX < COUNT
    #set PRODUCT := INDEX * FACTOR
    // INDEX * FACTOR = PRODUCT
    #set INDEX := INDEX + 1
#end
```

#### \#print message

Prints a message.

```cpp
#print A preprocessing information
```

#### \#abort message

Aborts preprocessing.

```cpp
#abort Some error message
```

## Version

0.1

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command line :

```bash
dmd genesis.d
```

## Version

0.1

## Author

Eric Pelzer (exstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
