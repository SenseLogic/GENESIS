#define CHECK
    #get MESSAGE

    MESSAGE
    ACTUAL
    EXPECTED

    #print MESSAGE
    #print ACTUAL
    #print EXPECTED

    #if $ACTUAL$ == $EXPECTED$
        Ok
        #print Ok
    #else
        Error ACTUAL == EXPECTED
        #abort Error ACTUAL == EXPECTED
    #end
#end

// ~~

#set! VARIABLE = BLABLA

#set ACTUAL = VARIABLE "MY VARIABLE NAME" MY@VARIABLE@NAME MYVARIABLENAME    // VARIABLE
#set EXPECTED = BLABLA "MY BLABLA NAME" MYBLABLANAME MYVARIABLENAME    // BLABLA

#call CHECK, Replace identifier

// ~~

#set* VARIABLE = BLABLA

#set ACTUAL = VARIABLE "MY VARIABLE NAME" MY@VARIABLE@NAME MYVARIABLENAME    // VARIABLE
#set EXPECTED = BLABLA "MY BLABLA NAME" MYBLABLANAME MYBLABLANAME    // BLABLA

#call CHECK, Replace string

// ~~

#set! FIRST_CONSTANT = "one"
#set! SECOND_CONSTANT = "two"

#if FIRST_CONSTANT == "one"
    FIRST_CONSTANT

    #if SECOND_CONSTANT != "two"
        OTHER
    #else
        SECOND_CONSTANT
    #end
#end

#if FIRST_CONSTANT != "one"
#else
    #if SECOND_CONSTANT != "two"
    #else
        OTHER OTHER
    #end
#end

// ~~

#include include.gi, "first", "#1", one, "0"
#include include.gi, "first", "#1", one, "1"
#include include.gi, "second", "#2", two, "2"
#include include.gi, "third", "#3", three, "3"
#include include.gi, "fourth", "#4", four, "4"
#include include.gi, "other", "?", any, "0"

#import include.gi

// ~~

FIRST_CONSTANT
SECOND_CONSTANT
THIRD_CONSTANT
FOURTH_CONSTANT
@FIRST_CONSTANT@@SECOND_CONSTANT@@THIRD_CONSTANT@
