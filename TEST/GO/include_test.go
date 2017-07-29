// ~~

    Replace identifier
    BLABLA "MY BLABLA NAME" MYBLABLANAME MYVARIABLENAME    // BLABLA
    BLABLA "MY BLABLA NAME" MYBLABLANAME MYVARIABLENAME    // BLABLA

    Ok

// ~~

    Replace string
    BLABLA "MY BLABLA NAME" MYBLABLANAME MYBLABLANAME    // BLABLA
    BLABLA "MY BLABLA NAME" MYBLABLANAME MYBLABLANAME    // BLABLA

    Ok

// ~~

"one"

"two"

OTHER OTHER

// ~~

FIRST
CASE

Parameters : "first" "#1" "one" "0"
Message : First case ( "first" "#1" "one" "0" )
Sum : 3
Total : 6

FIRST
CASE

Parameters : "first" "#1" "one" "1"
Message : First case ( "first" "#1" "one" "1" )
Sum : 3
Total : 6

SECOND
CASE

Parameters : "second" "#2" "two" "2"
Message : Second case ( "second" "#2" "two" "2" )
Sum : 3
Total : 6

THIRD
CASE

Parameters : "third" "#3" "three" "3"
Message : Third case ( "third" "#3" "three" "3" )
Sum : 3
Total : 6

FOURTH
CASE

Parameters : "fourth" "#4" "four" "4"
Message : Fourth case ( "fourth" "#4" "four" "4" )
Sum : 3
Total : 6

OTHER
CASE

Parameters : "other" "?" "any" "0"
Message : Other case ( "other" "?" "any" "0" )
Sum : 3
Total : 6

// ~~

"one"
"two"
"one" + "two"
FOURTH_CONSTANT
"one""two""one" + "two"
