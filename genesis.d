/*
    This file is part of the Genesis distribution.

    https://github.com/senselogic/GENESIS

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Genesis is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Genesis is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
*/

// == LOCAL

// -- IMPORTS

import std.algorithm : countUntil, max, min;
import std.array : array;
import std.ascii : isAlpha, isDigit;
import std.conv : to;
import std.file : dirEntries, exists, getcwd, readText, write, SpanMode;
import std.math : cos, sin, tan, asin, acos, atan, atan2, ceil, floor, round, trunc, fmod, abs, sqrt, pow, log, PI;
import std.path : asNormalizedPath, chainPath, dirName;
import std.random : uniform;
import std.stdio : writeln;
import std.string : endsWith, indexOf, join, lineSplitter, replace, startsWith, split, strip, stripLeft, stripRight, toLower, toUpper;

// == GLOBAL

// -- VARIABLES

bool
    DebugOptionIsEnabled,
    JoinLinesOptionIsEnabled,
    RecursiveOptionIsEnabled,
    VerboseOptionIsEnabled,
    FatalOptionIsEnabled;
string
    InputFilter,
    InputExtension,
    InputFolderPath,
    OutputExtension,
    OutputFolderPath;

// -- FUNCTIONS

// .. ERROR

void Abort(
    string message,
    string line = "",
    string file_path = "",
    int line_index = 0
    )
{
    writeln( "*** ERROR : ", message );

    if ( file_path != "" )
    {
        writeln( file_path, "(", ( line_index + 1 ), ") : ", line );
    }
    else if ( line != "" )
    {
        writeln( line );
    }

    if ( FatalOptionIsEnabled )
    {
        throw new Exception( message ~ line );
    }
}

// .. STRING

string toMinorCase(
    string text
    )
{
    return text[ 0 .. 1 ].toLower() ~ text[ 1 .. $ ];
}

// ~~

string toMajorCase(
    string text
    )
{
    return text[ 0 .. 1 ].toUpper() ~ text[ 1 .. $ ];
}

// ~~

string toSnakeCase(
    string text
    )
{
    char
        character,
        prior_character;
    string
        snake_case_text;

    snake_case_text = "";
    character = 0;

    foreach ( character_index; 0 .. text.length )
    {
        prior_character = character;
        character = text[ character_index ];

        if ( ( ( prior_character >= 'a' && prior_character <= 'z' )
               && ( ( character >= 'A' && character <= 'Z' )
                    || ( character >= '0' && character <= '9' ) ) )
             || ( ( prior_character >= '0' && prior_character <= '9' )
                  && ( ( character >= 'a' && character <= 'z' )
                       || ( character >= 'A' && character <= 'Z' ) ) ) )
        {
            snake_case_text ~= '_';
        }

        snake_case_text ~= character;
    }

    return snake_case_text.toLower();
}

// ~~

string toPascalCase(
    string text
    )
{
    string[]
        word_array;

    word_array = text.toLower().split( "_" );

    foreach ( ref word; word_array )
    {
        word = word.toMajorCase();
    }

    return word_array.join( "" );
}


// ~~

string toCamelCase(
    string text
    )
{
    return text.toPascalCase().toMajorCase();
}

// ~~

string toQuoted(
    string text
    )
{
    char
        character;
    int
        character_index;
    string
        quoted_text;
        
    quoted_text = "\"";
        
    for ( character_index = 0;
          character_index < text.length;
          ++character_index )
    {
        character = text[ character_index ];
        
        if ( character == '\"' )
        {
            quoted_text ~= "\\\"";
        }
        else if ( character == '\r' )
        {
            quoted_text ~= "\\r";
        }
        else if ( character == '\n' )
        {
            quoted_text ~= "\\n";
        }
        else if ( character == '\t' )
        {
            quoted_text ~= "\\t";
        }
        else
        {
            quoted_text ~= character;
        }
    }
    
    quoted_text ~= "\"";
    
    return quoted_text;
}

// ~~

string toUnquoted(
    string text
    )
{
    char
        character;
    int
        character_index;
    string
        unquoted_text;
        
    for ( character_index = 0;
          character_index < text.length;
          ++character_index )
    {
        character = text[ character_index ];
        
        if ( character == '\\'
             && character_index + 1 < text.length )
        {
            character = text[ character_index ];
        
            if ( character == 'r' )
            {
                unquoted_text ~= '\r';
            }
            else if ( character == 'n' )
            {
                unquoted_text ~= '\n';
            }
            else if ( character == 't' )
            {
                unquoted_text ~= '\t';
            }
            else
            {
                unquoted_text ~= character;
            }
            
            ++character_index;
        }
        else
        {
            unquoted_text ~= character;
        }
    }
    
    return unquoted_text;
}

// ~~

bool GetBooleanValue(
    string text
    )
{
    EXPRESSION
        expression;
    TOKEN
        token;

    expression = new EXPRESSION( text );

    return expression.Evaluate().GetInteger() ? true : false;
}

// ~~

string GetStringValue(
    string text
    )
{
    EXPRESSION
        expression;
    TOKEN
        token;

    expression = new EXPRESSION( text );

    return expression.Evaluate().GetString();
}

// ~~

bool HasEndingComment(
    string text
    )
{
    string[]
        word_array;

    word_array = GetWordArray( text, "//" );

    return word_array.length > 1;
}

// ~~

string FixIndentation(
    string text,
    int indentation
    )
{
    while ( indentation < 0
            && text.startsWith( "    " ) )
    {
        text = text[ 4 .. $ ];
        indentation += 4;
    }

    while ( indentation > 0 )
    {
        text = "    " ~ text;
        indentation -= 4;
    }

    return text;
}

// ~~

bool IsIdentifierCharacter(
    char character
    )
{
    return (
        ( character >= 'a' && character <= 'z' )
        || ( character >= 'A' && character <= 'Z' )
        || ( character >= '0' && character <= '9' )
        || character == '_'
        );
}

// ~~

string GetVariableName(
    string text
    )
{
    if ( text.startsWith( '.' ) )
    {
        return text[ 1 .. $ ];
    }
    else
    {
        return text;
    }
}

// ~~

string[] GetWordArray(
    string text,
    string separator
    )
{
    char
        character,
        state;
    int
        character_index;
    string[]
        word_array;

    word_array = [ "" ];
    state = 0;

    for ( character_index = 0;
          character_index < text.length;
          ++character_index )
    {
        character = text[ character_index ];

        if ( character == separator[ 0 ]
             && character_index + separator.length <= text.length
             && text[ character_index .. character_index + separator.length ] == separator )
        {
            word_array ~= "";
        }
        else
        {
            word_array[ word_array.length - 1 ] ~= character;

            if ( "'\"`".indexOf( character ) >= 0 )
            {
                if ( state == 0 )
                {
                    state = character;
                }
                else if ( character == state )
                {
                    state = 0;
                }

            }
            else if ( character == '\\'
                      && character_index + 1 < text.length
                      && state != 0 )
            {
                ++character_index;

                word_array[ word_array.length - 1 ] ~= text[ character_index ];
            }
        }
    }

    return word_array;
}

// ~~

void TrimWordArray(
    string[] word_array
    )
{
    foreach ( ref word; word_array )
    {
        word = word.strip();
    }
}

// .. PATH

string GetNormalizedPath(
    string path
    )
{
    if ( path.startsWith( '/' )
         || path.indexOf( ':' ) >= 0 )
    {
        return path.asNormalizedPath().array;
    }
    else
    {
        return chainPath( getcwd(), path ).asNormalizedPath().array;
    }
}

// ~~

string ReplaceFolderPath(
    string file_path,
    string input_path,
    string output_path
    )
{
    if ( input_path != output_path
         && file_path[ 0 .. input_path.length ] == input_path )
    {
        return output_path ~ file_path[ input_path.length .. $ ];
    }
    else
    {
        return file_path;
    }
}

// -- TYPES

// .. TOKEN TYPE

enum TOKEN_TYPE
{
    None,
    String,
    Real,
    Integer,
    Identifier,
    Operator,
    OpeningParenthesis,
    ClosingParenthesis
}

// .. TOKEN

class TOKEN
{
    // -- ATTRIBUTES

    TOKEN_TYPE
        Type;
    string
        Text;
    double
        Real;
    long
        Integer;

    // -- CONSTRUCTORS

    this(
        )
    {
        Type = TOKEN_TYPE.None;
    }
        
    // ~~
        
    this(
        string text
        )
    {
        Type = TOKEN_TYPE.String;
        Text = text;
    }
    
    // ~~
        
    this(
        double real_
        )
    {
        Type = TOKEN_TYPE.Real;
        Real = real_;
    }
    
    // ~~
        
    this(
        long integer
        )
    {
        Type = TOKEN_TYPE.Integer;
        Integer = integer;
    }
    
    // ~~
        
    this(
        bool boolean
        )
    {
        Type = TOKEN_TYPE.Integer;
        Integer = boolean ? 1 : 0;
    }
    
    // -- INQUIRIES
    
    string GetString(
        )
    {
        if ( Type == TOKEN_TYPE.String )
        {
            return Text;
        }
        else if ( Type == TOKEN_TYPE.Real )
        {
            return Real.to!string();
        }
        else if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer.to!string();
        }
        else
        {
            Abort( "Not string : ", Text );

            return "";
        }
    }
    
    // ~~
    
    double GetReal(
        )
    {
        if ( Type == TOKEN_TYPE.Real )
        {
            return Real;
        }
        else if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer.to!double();
        }
        else
        {
            Abort( "Not real : ", Text );

            return 0.0;
        }
    }
    
    // ~~
    
    long GetInteger(
        )
    {
        if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer;
        }
        else
        {
            Abort( "Not integer : ", Text );

            return 0;
        }
    }
    
    // ~~
    
    string ToString(
        )
    {
        if ( Type == TOKEN_TYPE.Real )
        {
            return Real.to!string();
        }
        else if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer.to!string();
        }
        else
        {
            return Text;
        }
    }

    // ~~
    
    double ToReal(
        )
    {
        if ( Type == TOKEN_TYPE.Real )
        {
            return Real;
        }
        else if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer.to!double();
        }
        else
        {
            return Text.to!double();
        }
    }
    
    // ~~
    
    long ToInteger(
        )
    {
        if ( Type == TOKEN_TYPE.Real )
        {
            return Real.to!long();
        }
        else if ( Type == TOKEN_TYPE.Integer )
        {
            return Integer;
        }
        else
        {
            return Text.to!long();
        }
    }
}

// -- FUNCTIONS

// .. TOKEN ARRAY

string GetText(
    ref TOKEN[] token_array
    )
{
    string
        text;

    foreach ( token; token_array )
    {
        text ~= token.Text;
        text ~= ' ';
    }

    text = text.strip();

    return text;
}

// ~~

void Dump(
    ref TOKEN[] token_array
    )
{
    foreach ( token_index, token; token_array )
    {
        if ( token.Type == TOKEN_TYPE.Real )
        {
            writeln( "[ ", token_index, " ] : ", token.Type, ", ", token.Real );
        }
        else if ( token.Type == TOKEN_TYPE.Integer )
        {
            writeln( "[ ", token_index, " ] : ", token.Type, ", ", token.Integer );
        }
        else
        {
            writeln( "[ ", token_index, " ] : ", token.Type, ", ", token.Text );
        }
    }
}

// -- TYPES

// .. EXPRESSION

class EXPRESSION
{
    // -- ATTRIBUTES

    TOKEN[]
        TokenArray;

    // -- CONSTRUCTORS

    this(
        string text
        )
    {
        SetText( text );
    }

    // -- INQUIRIES

    TOKEN GetResult(
        ref TOKEN[] token_array
        )
    {
        if ( token_array.length == 1
             && ( token_array[ 0 ].Type == TOKEN_TYPE.String
                  || token_array[ 0 ].Type == TOKEN_TYPE.Real
                  || token_array[ 0 ].Type == TOKEN_TYPE.Integer ) )
        {
            return token_array[ 0 ];
        }
        else
        {
            Abort( "Bad result", token_array.GetText() );

            return null;
        }
    }

    // -- OPERATIONS
        
    void SetText(
        string text
        )
    {
        char
            character,
            delimiter_character,
            next_character;
        int
            character_index;
        TOKEN
            token;

        TokenArray = [];

        token = null;
        delimiter_character = 0;

        for ( character_index = 0;
              character_index <= text.length;
              ++character_index )
        {
            if ( character_index < text.length )
            {
                character = text[ character_index ];
            }
            else
            {
                character = 0;
            }
            
            if ( character_index + 1 < text.length )
            {
                next_character = text[ character_index + 1 ];
            }
            else
            {
                next_character = 0;
            }
            
            if ( token !is null )
            {
                if ( token.Type == TOKEN_TYPE.String )
                {
                    if ( character == delimiter_character )
                    {
                        token = null;

                        continue;
                    }
                    else if ( character == '\\' )
                    {
                        token.Text ~= next_character;
                        ++character_index;
                    }
                    else
                    {
                        token.Text ~= character;
                    }
                }
                else if ( ( token.Type == TOKEN_TYPE.Integer
                            && ( isDigit( character )
                                 || character == '.' ) )
                          || ( token.Type == TOKEN_TYPE.Identifier
                               && ( isAlpha( character )
                                    || character == '_' ) )
                          || ( token.Type == TOKEN_TYPE.Operator
                               && "~+-*/&|!=<>".indexOf( character ) >= 0 ) )
                {
                    token.Text ~= character;
                }
                else
                {
                    if ( token.Type == TOKEN_TYPE.Integer )
                    {
                        if ( token.Text.indexOf( '.' ) >= 0 )
                        {
                            token.Type = TOKEN_TYPE.Real;
                            token.Real = token.Text.to!double();
                        }
                        else
                        {
                            token.Integer = token.Text.to!long();
                        }
                    }
                    else if ( token.Type == TOKEN_TYPE.Identifier )
                    {
                        if ( token.Text == "false" )
                        {
                            token.Type = TOKEN_TYPE.Integer;
                            token.Integer = 0;
                        }
                        else if ( token.Text == "true" )
                        {
                            token.Type = TOKEN_TYPE.Integer;
                            token.Integer = 1;
                        }
                        else if ( token.Text == "pi" )
                        {
                            token.Type = TOKEN_TYPE.Real;
                            token.Real = PI;
                        }
                    }
                    
                    token = null;
                }
            }
            
            if ( token is null
                 && character != ' '
                 && character != '\t'
                 && character != 0 )
            {
                token = new TOKEN;

                if ( character == '\''
                     || character == '\"'
                     || character == '`' )
                {
                    token.Type = TOKEN_TYPE.String;
                    delimiter_character = character;
                }
                else if ( isDigit( character )
                          || ( character == '-' 
                               && isDigit( next_character ) ) )
                {
                    token.Type = TOKEN_TYPE.Integer;
                    token.Text ~= character;
                }
                else if ( isAlpha( character )
                          || character == '_' )
                {
                    token.Type = TOKEN_TYPE.Identifier;
                    token.Text ~= character;
                }
                else if ( "~+-*/&|!=<>".indexOf( character ) >= 0 )
                {
                    token.Type = TOKEN_TYPE.Operator;
                    token.Text ~= character;
                }
                else if ( character == '(' )
                {
                    token.Type = TOKEN_TYPE.OpeningParenthesis;
                    token.Text ~= character;
                }
                else if ( character == ')' )
                {
                    token.Type = TOKEN_TYPE.ClosingParenthesis;
                    token.Text ~= character;
                }
                else
                {
                    Abort( "Invalid character : ", text );
                }

                TokenArray ~= token;

                if ( token.Type == TOKEN_TYPE.OpeningParenthesis
                     || token.Type == TOKEN_TYPE.ClosingParenthesis )
                {
                    token = null;
                }
            }
        }
    }
    
    // ~~
    
    TOKEN Evaluate(
        TOKEN[] token_array
        )
    {
        TOKEN
            result_token;

        if ( token_array.length > 1 )
        {
            if ( token_array[ 0 ].Type == TOKEN_TYPE.Operator )
            {
                if ( token_array[ 0 ].Text == "-"
                     && token_array.length == 2 )
                {
                    if ( token_array[ 1 ].Type == TOKEN_TYPE.Real )
                    {
                        return new TOKEN( -token_array[ 1 ].GetReal() );
                    }
                    else
                    {
                        return new TOKEN( -token_array[ 1 ].GetInteger() );
                    }
                }
                else if ( token_array[ 0 ].Text == "!"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetInteger() ? 0 : 1 );
                }
                else
                {
                    Abort( "Bad unary operator call : ", token_array[ 0 ].Text );
                }
            }
            else if ( token_array[ 0 ].Type == TOKEN_TYPE.Identifier )
            {
                if ( token_array[ 0 ].Text == "String"
                     && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].ToString() );
                }
                else if ( token_array[ 0 ].Text == "Real"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].ToReal() );
                }
                else if ( token_array[ 0 ].Text == "Integer"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].ToInteger() );
                }
                else if ( token_array[ 0 ].Text == "LowerCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toLower() );
                }
                else if ( token_array[ 0 ].Text == "UpperCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toUpper() );
                }
                else if ( token_array[ 0 ].Text == "MinorCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toMinorCase() );
                }
                else if ( token_array[ 0 ].Text == "MajorCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toMajorCase() );
                }
                else if ( token_array[ 0 ].Text == "SnakeCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toSnakeCase() );
                }
                else if ( token_array[ 0 ].Text == "CamelCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toCamelCase() );
                }
                else if ( token_array[ 0 ].Text == "PascalCase"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toPascalCase() );
                }
                else if ( token_array[ 0 ].Text == "Quote"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toQuoted() );
                }
                else if ( token_array[ 0 ].Text == "Unquote"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().toUnquoted() );
                }
                else if ( token_array[ 0 ].Text == "Strip"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().strip() );
                }
                else if ( token_array[ 0 ].Text == "StripLeft"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().stripLeft() );
                }
                else if ( token_array[ 0 ].Text == "StripRight"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().stripRight() );
                }
                else if ( token_array[ 0 ].Text == "Replace"
                          && token_array.length == 4 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().replace( token_array[ 2 ].GetString(), token_array[ 3 ].GetString() ) );
                }
                else if ( token_array[ 0 ].Text == "Index"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().indexOf( token_array[ 2 ].GetString() ) );
                }
                else if ( token_array[ 0 ].Text == "Contains"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().indexOf( token_array[ 2 ].GetString() ) >= 0 );
                }
                else if ( token_array[ 0 ].Text == "HasPrefix"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().startsWith( token_array[ 2 ].GetString() ) );
                }
                else if ( token_array[ 0 ].Text == "HasSuffix"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetString().endsWith( token_array[ 2 ].GetString() ) );
                }
                else if ( token_array[ 0 ].Text == "Ceil"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().ceil() );
                }
                else if ( token_array[ 0 ].Text == "Floor"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().floor() );
                }
                else if ( token_array[ 0 ].Text == "Round"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().round() );
                }
                else if ( token_array[ 0 ].Text == "Trunc"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().trunc() );
                }
                else if ( token_array[ 0 ].Text == "Remainder"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().fmod( token_array[ 2 ].GetReal() ) );
                }
                else if ( token_array[ 0 ].Text == "Power"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().pow( token_array[ 2 ].GetReal() ) );
                }
                else if ( token_array[ 0 ].Text == "Log"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().log() );
                }
                else if ( token_array[ 0 ].Text == "SquareRoot"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().sqrt() );
                }
                else if ( token_array[ 0 ].Text == "Cosinus"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().cos() );
                }
                else if ( token_array[ 0 ].Text == "Sinus"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().sin() );
                }
                else if ( token_array[ 0 ].Text == "Tangent"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().tan() );
                }
                else if ( token_array[ 0 ].Text == "ArcCosinus"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().acos() );
                }
                else if ( token_array[ 0 ].Text == "ArcSinus"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().asin() );
                }
                else if ( token_array[ 0 ].Text == "ArcTangent"
                          && token_array.length == 2 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().atan() );
                }
                else if ( token_array[ 0 ].Text == "ArcTangent"
                          && token_array.length == 3 )
                {
                    return new TOKEN( token_array[ 1 ].GetReal().atan2( token_array[ 2 ].GetReal() ) );
                }
                else if ( token_array[ 0 ].Text == "Absolute"
                          && token_array.length == 2 )
                {
                    if ( token_array[ 1 ].Type == TOKEN_TYPE.Integer )
                    {
                        return new TOKEN( token_array[ 1 ].GetInteger().abs() );
                    }
                    else
                    {
                        return new TOKEN( token_array[ 1 ].GetReal().abs() );
                    }
                }
                else if ( token_array[ 0 ].Text == "Random"
                          && token_array.length == 3 )
                {
                    if ( token_array[ 1 ].Type == TOKEN_TYPE.Integer
                              && token_array[ 2 ].Type == TOKEN_TYPE.Integer )
                    {
                        return new TOKEN( token_array[ 1 ].GetInteger().uniform( token_array[ 2 ].GetInteger() ) );
                    }
                    else
                    {
                        return new TOKEN( token_array[ 1 ].GetReal().uniform( token_array[ 2 ].GetReal() ) );
                    }
                }
                else if ( token_array[ 0 ].Text == "Minimum"
                          && token_array.length == 3 )
                {
                    if ( token_array[ 1 ].Type == TOKEN_TYPE.String
                         || token_array[ 2 ].Type == TOKEN_TYPE.String )
                    {
                        return new TOKEN( token_array[ 1 ].GetString().min( token_array[ 2 ].GetString() ) );
                    }
                    else if ( token_array[ 1 ].Type == TOKEN_TYPE.Real
                              || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                    {
                        return new TOKEN( token_array[ 1 ].GetReal().min( token_array[ 2 ].GetReal() ) );
                    }
                    else
                    {
                        return new TOKEN( token_array[ 1 ].GetInteger().min( token_array[ 2 ].GetInteger() ) );
                    }
                }
                else if ( token_array[ 0 ].Text == "Maximum"
                          && token_array.length == 3 )
                {
                    if ( token_array[ 1 ].Type == TOKEN_TYPE.String
                         || token_array[ 2 ].Type == TOKEN_TYPE.String )
                    {
                        return new TOKEN( token_array[ 1 ].GetString().max( token_array[ 2 ].GetString() ) );
                    }
                    else if ( token_array[ 1 ].Type == TOKEN_TYPE.Real
                              || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                    {
                        return new TOKEN( token_array[ 1 ].GetReal().max( token_array[ 2 ].GetReal() ) );
                    }
                    else
                    {
                        return new TOKEN( token_array[ 1 ].GetInteger().max( token_array[ 2 ].GetInteger() ) );
                    }
                }
                else
                {
                    Abort( "Bad function call : ", token_array[ 0 ].Text );
                }
            }
            else 
            {
                while ( token_array.length >= 3
                        && token_array[ 1 ].Type == TOKEN_TYPE.Operator )
                {
                    if ( token_array[ 1 ].Text == "~" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetString() ~ token_array[ 2 ].GetString() );
                    }
                    else if ( token_array[ 1 ].Text == "+" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                             || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() + token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() + token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "-" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                             || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() - token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() - token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "*" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                             || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() * token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() * token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "/" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                             || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() / token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() / token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "%" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() % token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "&&" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() && token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "||" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() || token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "&" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() & token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "|" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() | token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "<<" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() << token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == ">>" )
                    {
                        result_token = new TOKEN( token_array[ 0 ].GetInteger() >> token_array[ 2 ].GetInteger() );
                    }
                    else if ( token_array[ 1 ].Text == "<" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() < token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() < token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() < token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "<=" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() <= token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() <= token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() <= token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "==" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() == token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() == token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() == token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == "!=" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() != token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() != token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() != token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == ">=" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() >= token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() >= token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() >= token_array[ 2 ].GetInteger() );
                        }
                    }
                    else if ( token_array[ 1 ].Text == ">" )
                    {
                        if ( token_array[ 0 ].Type == TOKEN_TYPE.String
                             || token_array[ 2 ].Type == TOKEN_TYPE.String )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetString() > token_array[ 2 ].GetString() );
                        }
                        else if ( token_array[ 0 ].Type == TOKEN_TYPE.Real
                                  || token_array[ 2 ].Type == TOKEN_TYPE.Real )
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetReal() > token_array[ 2 ].GetReal() );
                        }
                        else
                        {
                            result_token = new TOKEN( token_array[ 0 ].GetInteger() > token_array[ 2 ].GetInteger() );
                        }
                    }
                    else
                    {
                        Abort( "Bad binary operator call : ", token_array[ 1 ].Text );
                    }

                    token_array = result_token ~ token_array[ 3 .. $ ];
                }
            }
        }
        else
        {
            Abort( "Bad expression", token_array.GetText() );
        }

        return GetResult( token_array );
    }
    
    // ~~
    
    TOKEN Evaluate(
        )
    {
        int
            first_token_index,
            last_token_index,
            token_index;
        TOKEN
            token;
        
        while ( TokenArray.length > 1 )
        {
            first_token_index = -1;
            last_token_index = -1;
            
            for ( token_index = 0;
                  token_index < TokenArray.length;
                  ++token_index )
            {
                token = TokenArray[ token_index ];

                if ( token.Type == TOKEN_TYPE.OpeningParenthesis )
                {
                    first_token_index = token_index;
                }
                else if ( token.Type == TOKEN_TYPE.ClosingParenthesis )
                {
                    last_token_index = token_index;

                    break;
                }
            }
            
            if ( first_token_index < last_token_index )
            {
                token = Evaluate( TokenArray[ first_token_index + 1 .. last_token_index ] );
                
                TokenArray 
                    = TokenArray[ 0 .. first_token_index ]
                      ~ token
                      ~ TokenArray[ last_token_index + 1 .. $ ];
            }
            else
            {
                return Evaluate( TokenArray );
            }
        }

        return GetResult( TokenArray );
    }
}

// .. VARIABLE

class VARIABLE
{
    // -- ATTRIBUTES

    string
        Name,
        Value;
    bool
        ItIsIdentifier;
    
    // -- CONSTRUCTORS
        
    this(
        string name,
        string value,
        bool it_is_identifier
        )
    {
        Name = name;
        Value = value;
        ItIsIdentifier = it_is_identifier;
    }
    
    // -- INQUIRIES
    
    string ReplaceVariableName(
        string text
        )
    {
        char
            next_character,
            prior_character;
        int
            first_character_index,
            variable_character_index;
        string
            old_text;
            
        do
        {
            old_text = text;

            first_character_index = 0;

            while ( first_character_index < text.length )
            {
                variable_character_index = text.indexOf( Name, first_character_index ).to!int();

                if ( variable_character_index >= 0 )
                {
                    if ( variable_character_index > 0 )
                    {
                        prior_character = text[ variable_character_index - 1 ];
                    }
                    else
                    {
                        prior_character = 0;
                    }

                    if ( variable_character_index + Name.length < text.length )
                    {
                        next_character = text[ variable_character_index + Name.length ];
                    }
                    else
                    {
                        next_character = 0;
                    }

                    if ( !ItIsIdentifier
                         || ( !IsIdentifierCharacter( prior_character )
                              && !IsIdentifierCharacter( next_character ) ) )
                    {
                        if ( prior_character == '@'
                             && next_character == '@' )
                        {
                            text
                                = text[ 0 .. variable_character_index - 1 ]
                                  ~ Value
                                  ~ text[ variable_character_index + Name.length + 1 .. $ ];

                            first_character_index += Value.length - 1;
                        }
                        else if ( prior_character == '$'
                                  && next_character == '$' )
                        {
                            text
                                = text[ 0 .. variable_character_index - 1 ]
                                  ~ Value.toQuoted()
                                  ~ text[ variable_character_index + Name.length + 1 .. $ ];

                            first_character_index += Value.length - 1;
                        }
                        else
                        {
                            text
                                = text[ 0 .. variable_character_index ]
                                  ~ Value
                                  ~ text[ variable_character_index + Name.length .. $ ];

                            first_character_index += Value.length;
                        }
                    }
                    else
                    {
                        first_character_index += Name.length;
                    }
                }
                else
                {
                    break;
                }
            }
        }
        while ( text != old_text );

        return text;
    }
}

// .. DEFINITION

class DEFINITION
{
    // -- ATTRIBUTES

    string
        Name,
        Text;

    // -- CONSTRUCTORS

    this(
        string name,
        string text
        )
    {
        Name = name;
        Text = text;
    }
}

// .. CONTEXT

class CONTEXT
{
    // -- ATTRIBUTES

    CONTEXT
        SuperContext,
        GlobalContext;
    string[]
        IncludedFilePathArray;
    VARIABLE[ string ]
        VariableMap;
    DEFINITION[ string ]
        DefinitionMap;

    // -- INQUIRIES
        
    string ReplaceVariableNames(
        string text
        )
    {
        string
            old_text,
            older_text;
        CONTEXT
            super_context;
        VARIABLE
            variable;

        do
        {
            older_text = text;

            for ( super_context = this;
                  super_context !is null;
                  super_context = super_context.SuperContext )
            {
                do
                {
                    old_text = text;

                    foreach ( ref variable; super_context.VariableMap )
                    {
                        text = variable.ReplaceVariableName( text );
                    }
                }
                while ( text != old_text );
            }
        }
        while ( text != older_text );

        return text;
    }

    // ~~

    VARIABLE FindVariable(
        string variable_name
        )
    {
        VARIABLE *
            variable;
            
        variable = variable_name in VariableMap;
        
        if ( variable !is null )
        {
            return *variable;
        }
        else if ( SuperContext !is null )
        {
            return SuperContext.FindVariable( variable_name );
        }
        else
        {
            return null;
        }
    }

    // ~~

    DEFINITION FindDefinition(
        string definition_name
        )
    {
        DEFINITION *
            definition;
            
        definition = definition_name in DefinitionMap;
        
        if ( definition !is null )
        {
            return *definition;
        }
        else if ( SuperContext !is null )
        {
            return SuperContext.FindDefinition( definition_name );
        }
        else
        {
            return null;
        }
    }

    // ~~

    CONTEXT GetSubContext(
        )
    {
        CONTEXT
            sub_context;

        sub_context = new CONTEXT;
        sub_context.SuperContext = this;
        sub_context.GlobalContext = GlobalContext;

        return sub_context;
    }

    // ~~

    void Dump(
        )
    {
        writeln( VariableMap.length, " variables :" );

        foreach ( ref variable; VariableMap )
        {
            writeln( variable );
        }

        writeln( VariableMap.length, " definitions :" );

        foreach ( ref definition; DefinitionMap )
        {
            writeln( definition );
        }

        if ( SuperContext !is null )
        {
            SuperContext.Dump();
        }
    }
}

// .. CONDITION

class CONDITION
{
    // -- ATTRIBUTES

    bool
        ItWasTrue,
        ItIsTrue;

    // -- CONSTRUCTORS

    this(
        bool it_was_true,
        bool it_is_true
        )
    {
        ItWasTrue = it_was_true;
        ItIsTrue = it_is_true;
    }
}

// .. LINE ARRAY

int[] GetIndentationArray(
    ref string[] line_array,
    int indentation
    )
{
    int[]
        indentation_array;

    indentation_array = new int[ line_array.length ];

    foreach ( line_index; 0 .. line_array.length )
    {
        indentation_array[ line_index ] = indentation;
    }

    return indentation_array;
}

// ~~

void LogLineArray(
    string[] line_array,
    int[] indentation_array
    )
{
    foreach ( line_index; 0 .. indentation_array.length )
    {
        writeln( line_index, " | ", indentation_array[ line_index ], " : ", line_array[ line_index ] );
    }
}

// ~~

int FindEndLineIndex(
    string[] line_array,
    int line_index
    )
{
    int
        level,
        end_line_index;
    string
        line,
        stripped_line;

    level = 0;

    for ( end_line_index = line_index;
          end_line_index < line_array.length;
          ++end_line_index )
    {
        line = line_array[ end_line_index ];
        stripped_line = line.strip();

        if ( stripped_line.startsWith( "#if" )
             || stripped_line.startsWith( "#while" )
             || stripped_line.startsWith( "#define" ) )
        {
            ++level;
        }
        else if ( stripped_line.startsWith( "#end" ) )
        {
            if ( level > 1 )
            {
                --level;
            }
            else
            {
                break;
            }
        }
    }

    return end_line_index;
}

// ~~

void DefineLineArray(
    ref string[] line_array,
    ref int[] indentation_array,
    int line_index,
    string definition_name,
    CONTEXT context
    )
{
    int
        end_line_index;
    string
        definition_text;

    end_line_index = FindEndLineIndex( line_array, line_index );

    if ( end_line_index >= line_array.length )
    {
        Abort( "Missing #end", line_array[ line_index ].strip() );
    }
    else
    {
        definition_text = line_array[ line_index + 1 .. end_line_index ].join( "\n" );

        context.DefinitionMap[ definition_name ] = new DEFINITION( definition_name, definition_text );

        line_array = line_array[ 0 .. line_index ] ~ line_array[ end_line_index + 1 .. $ ];
        indentation_array = indentation_array[ 0 .. line_index ] ~ indentation_array[ end_line_index + 1 .. $ ];
    }
}

// ~~

void InsertLineArray(
    ref string[] line_array,
    ref int[] indentation_array,
    ref int line_index,
    string inserted_file_path,
    int indentation
    )
{
    int[]
        inserted_indentation_array;
    string
        inserted_file_text;
    string[]
        inserted_line_array;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Inserting file : ", inserted_file_path );
    }

    inserted_file_text = inserted_file_path.readText();

    inserted_line_array = inserted_file_text.split( "\n" );
    inserted_indentation_array = GetIndentationArray( inserted_line_array, indentation );

    line_array = line_array[ 0 .. line_index ] ~ inserted_line_array ~ line_array[ line_index + 1 .. $ ];
    indentation_array = indentation_array[ 0 .. line_index ] ~ inserted_indentation_array ~ indentation_array[ line_index + 1 .. $ ];

    line_index += inserted_line_array.length - 1;
}

// ~~

void IncludeLineArray(
    ref string[] line_array,
    ref int[] indentation_array,
    int line_index,
    string called_definition_name,
    string included_file_path,
    string[] argument_value_array,
    CONTEXT context,
    int indentation
    )
{
    int[]
        included_indentation_array;
    string
        included_file_text;
    string[]
        included_line_array;
    DEFINITION
        definition;

    if ( called_definition_name != "" )
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "Calling function : ", called_definition_name );
        }

        included_file_path = called_definition_name;

        definition = context.FindDefinition( called_definition_name );

        if ( definition !is null )
        {
            included_file_text = definition.Text;
        }
        else
        {
            Abort( "Unkown function ", called_definition_name );
        }
    }
    else
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "Including file : ", included_file_path );
        }

        if ( context.GlobalContext.IncludedFilePathArray.countUntil( included_file_path ) < 0 )
        {
            context.GlobalContext.IncludedFilePathArray ~= included_file_path;
        }

        included_file_text = included_file_path.readText();
    }

    included_line_array = included_file_text.split( "\n" );
    included_indentation_array = GetIndentationArray( included_line_array, indentation );

    ProcessLineArray(
        included_line_array,
        included_indentation_array,
        included_file_path,
        argument_value_array,
        context,
        indentation
        );

    line_array = line_array[ 0 .. line_index ] ~ included_line_array ~ line_array[ line_index + 1 .. $ ];
    indentation_array = indentation_array[ 0 .. line_index ] ~ included_indentation_array ~ indentation_array[ line_index + 1 .. $ ];
}

// ~~

void RepeatLineArray(
    ref string[] line_array,
    ref int[] indentation_array,
    int line_index,
    string command_expression,
    CONTEXT context
    )
{
    int
        end_line_index;
    int[]
        inserted_indentation_array,
        repeated_indentation_array;
    string[]
        inserted_line_array,
        repeated_line_array;

    end_line_index = FindEndLineIndex( line_array, line_index );

    if ( end_line_index >= line_array.length )
    {
        Abort( "Missing #end", line_array[ line_index ].strip() );
    }
    else
    {
        repeated_line_array = line_array[ line_index + 1 .. end_line_index ];
        repeated_indentation_array = indentation_array[ line_index + 1 .. end_line_index ];

        line_array = line_array[ 0 .. line_index ] ~ line_array[ end_line_index + 1 .. $ ];
        indentation_array = indentation_array[ 0 .. line_index ] ~ indentation_array[ end_line_index + 1 .. $ ];

        while ( GetBooleanValue( context.ReplaceVariableNames( command_expression ) ) )
        {
            inserted_line_array = repeated_line_array.dup();
            inserted_indentation_array = repeated_indentation_array.dup();

            ProcessLineArray(
                inserted_line_array,
                inserted_indentation_array,
                "",
                [],
                context,
                0
                );

            line_array = line_array[ 0 .. line_index ] ~ inserted_line_array ~ line_array[ line_index .. $ ];
            indentation_array = indentation_array[ 0 .. line_index ] ~ inserted_indentation_array ~ indentation_array[ line_index .. $ ];

            line_index += inserted_line_array.length;
        }
    }
}

// ~~

void ProcessLineArray(
    ref string[] line_array,
    ref int[] indentation_array,
    string file_path,
    string[] argument_value_array,
    CONTEXT context,
    int indentation
    )
{
    string
        called_definition_name,
        command_expression,
        command_name,
        folder_path,
        defined_file_name,
        included_file_name,
        included_file_path,
        replaced_expression,
        line,
        stripped_line,
        variable_name,
        variable_value;
    int
        line_index;
    string[]
        command_array,
        included_file_argument_value_array,
        line_word_array;
    bool
        boolean_value,
        line_is_ignored,
        variable_is_identifier;
    CONDITION[]
        condition_array;
    CONTEXT
        sub_context;
    VARIABLE
        variable;

    folder_path = file_path.dirName();

    condition_array = [ new CONDITION( true, true ) ];
    indentation = 0;    // TODO

    command_array =
        [
            "#get",
            "#get*",
            "#get!",
            "#get*!",
            "#set",
            "#set*",
            "#set!",
            "#set*!",
            "#unset",
            "#unset!",
            "#define",
            "#define!",
            "#undefine",
            "#undefine!",
            "#call",
            "#insert",
            "#include",
            "#import",
            "#print",
            "#abort",
            "#dump",
            "#while",
            "#if",
            "#ifset",
            "#ifnotset",
            "#ifdefined",
            "#ifnotdefined",
            "#elseif",
            "#else",
            "#end",
        ];

    for ( line_index = 0;
          line_index < line_array.length;
          ++line_index )
    {
        line = line_array[ line_index ];
        stripped_line = line.strip();

        if ( DebugOptionIsEnabled )
        {
            writeln( file_path ~ " : ", line );
        }

        line_is_ignored = false;

        foreach ( ref condition; condition_array )
        {
            if ( !condition.ItIsTrue )
            {
                line_is_ignored = true;

                break;
            }
        }

        if ( stripped_line != "" )
        {
            if ( stripped_line.startsWith( '#' ) )
            {
                line_word_array = GetWordArray( stripped_line, " " );

                command_name = line_word_array[ 0 ];

                if ( command_array.countUntil( command_name ) >= 0 )
                {
                    if ( line_word_array.length > 1 )
                    {
                        command_expression = line_word_array[ 1 .. $ ].join( " " ).strip();
                    }
                    else
                    {
                        command_expression = "";
                    }

                    if ( !line_is_ignored )
                    {
                        if ( command_name == "#get"
                             || command_name == "#get*"
                             || command_name == "#get!"
                             || command_name == "#get*!" )
                        {
                            if ( command_expression == "" )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else if ( argument_value_array.length == 0 )
                            {
                                Abort( "Missing parameter", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                variable_name = command_expression;
                                variable_value = argument_value_array[ 0 ];
                                argument_value_array = argument_value_array[ 1 .. $ ];
                                variable_is_identifier = true;

                                if ( command_name.indexOf( '*' ) >= 0 )
                                {
                                    variable_is_identifier = false;
                                }

                                variable = new VARIABLE( variable_name, variable_value, variable_is_identifier );

                                if ( command_name.endsWith( '!' ) )
                                {
                                    context.GlobalContext.VariableMap[ variable.Name ] = variable;
                                }
                                else
                                {
                                    context.VariableMap[ variable.Name ] = variable;
                                }
                            }
                        }
                        else if ( command_name == "#set"
                                  || command_name == "#set*"
                                  || command_name == "#set!"
                                  || command_name == "#set*!" )
                        {
                            line_word_array = GetWordArray( command_expression, "=" );

                            if ( line_word_array.length < 1 )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                variable_name = line_word_array[ 0 ].strip();
                                variable_value = line_word_array[ 1 .. $ ].join( " " ).strip();
                                variable_is_identifier = true;

                                if ( command_name.indexOf( '*' ) >= 0 )
                                {
                                    command_name = command_name[ 0 .. $ - 1 ];
                                    variable_is_identifier = false;
                                }

                                if ( variable_name.endsWith( '#' ) )
                                {
                                    variable_name = variable_name[ 0 .. $ - 1 ];
                                }
                                else
                                {
                                    variable_value = context.ReplaceVariableNames( variable_value );
                                }

                                if ( variable_name.endsWith( ':' ) )
                                {
                                    variable_name = variable_name[ 0 .. $ - 1 ];
                                    variable_value = GetStringValue( variable_value );
                                }

                                if ( variable_name.endsWith( '$' ) )
                                {
                                    variable_name = variable_name[ 0 .. $ - 1 ];
                                    variable_value = variable_value.toQuoted();
                                }

                                if ( variable_name.endsWith( '@' ) )
                                {
                                    variable_name = variable_name[ 0 .. $ - 1 ].strip();
                                    variable_name = context.ReplaceVariableNames( variable_name );
                                }
                                else
                                {
                                    variable_name = variable_name.strip();
                                }

                                variable = new VARIABLE( variable_name, variable_value, variable_is_identifier );

                                if ( command_name.endsWith( '!' ) )
                                {
                                    context.GlobalContext.VariableMap[ variable.Name ] = variable;
                                }
                                else
                                {
                                    context.VariableMap[ variable.Name ] = variable;
                                }
                            }
                        }
                        else if ( command_name == "#unset"
                                  || command_name == "#unset!" )
                        {
                            if ( command_expression == "" )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                variable_name = GetVariableName( command_expression );

                                if ( command_name.endsWith( '!' ) )
                                {
                                    context.GlobalContext.VariableMap.remove( variable_name );
                                }
                                else
                                {
                                    context.VariableMap.remove( variable_name );
                                }
                            }
                        }
                        else if ( command_name == "#define"
                                  || command_name == "#define!" )
                        {
                            if ( command_name.endsWith( '!' ) )
                            {
                                DefineLineArray(
                                    line_array,
                                    indentation_array,
                                    line_index,
                                    command_expression,
                                    context.GlobalContext
                                    );
                            }
                            else
                            {
                                DefineLineArray(
                                    line_array,
                                    indentation_array,
                                    line_index,
                                    command_expression,
                                    context
                                    );
                            }

                            --line_index;

                            continue;
                        }
                        else if ( command_name == "#undefine"
                                  || command_name == "#undefine!" )
                        {
                            if ( command_expression == "" )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                if ( command_name.endsWith( '!' ) )
                                {
                                    context.GlobalContext.DefinitionMap.remove( command_expression );
                                }
                                else
                                {
                                    context.DefinitionMap.remove( command_expression );
                                }
                            }
                        }
                        else if ( command_name == "#insert" )
                        {
                            line_word_array = GetWordArray( command_expression, "," );

                            TrimWordArray( line_word_array );

                            if ( line_word_array.length < 1 )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                InsertLineArray(
                                    line_array,
                                    indentation_array,
                                    line_index,
                                    line_word_array[ 0 ],
                                    -indentation
                                    );

                                continue;
                            }
                        }
                        else if ( command_name == "#call"
                                  || command_name == "#include"
                                  || command_name == "#import" )
                        {
                            line_word_array = GetWordArray( command_expression, "," );

                            TrimWordArray( line_word_array );

                            if ( line_word_array.length < 1 )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                sub_context = context.GetSubContext();

                                if ( command_name == "#call" )
                                {
                                    called_definition_name = line_word_array[ 0 ];
                                    included_file_path = "";
                                }
                                else
                                {
                                    called_definition_name = "";
                                    included_file_path = chainPath( folder_path, line_word_array[ 0 ] ).array;
                                }

                                included_file_argument_value_array = line_word_array[ 1 .. $ ];

                                if ( command_name != "#import"
                                     || context.GlobalContext.IncludedFilePathArray.countUntil( included_file_path ) < 0 )
                                {
                                    IncludeLineArray(
                                        line_array,
                                        indentation_array,
                                        line_index,
                                        called_definition_name,
                                        included_file_path,
                                        included_file_argument_value_array,
                                        sub_context,
                                        -indentation
                                        );

                                    --line_index;

                                    continue;
                                }
                            }
                        }
                        else if ( command_name == "#print"
                                  || command_name == "#abort" )
                        {
                            replaced_expression = context.ReplaceVariableNames( command_expression );

                            if ( command_name == "#print" )
                            {
                                writeln( replaced_expression );
                            }
                            else
                            {
                                Abort( replaced_expression, stripped_line, file_path, line_index );
                            }
                        }
                        else if ( command_name == "#dump" )
                        {
                            context.Dump();
                        }
                        else if ( command_name == "#while" )
                        {
                            RepeatLineArray(
                                line_array,
                                indentation_array,
                                line_index,
                                command_expression,
                                context
                                );

                            --line_index;

                            continue;
                        }
                    }

                    if ( command_name == "#if"
                         || command_name == "#ifset"
                         || command_name == "#ifnotset"
                         || command_name == "#ifdefined"
                         || command_name == "#ifnotdefined" )
                    {
                        if ( line_is_ignored )
                        {
                            condition_array ~= new CONDITION( true, false );
                            indentation -= 4;
                        }
                        else
                        {
                            if ( command_expression == "" )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                if ( command_name == "#ifset" )
                                {
                                    boolean_value = ( context.FindVariable( command_expression ) !is null );
                                }
                                else if ( command_name == "#ifnotset" )
                                {
                                    boolean_value = ( context.FindVariable( command_expression ) is null );
                                }
                                else if ( command_name == "#ifdefined" )
                                {
                                    boolean_value = ( context.FindDefinition( command_expression ) !is null );
                                }
                                else if ( command_name == "#ifnotdefined" )
                                {
                                    boolean_value = ( context.FindDefinition( command_expression ) is null );
                                }
                                else
                                {
                                    replaced_expression = context.ReplaceVariableNames( command_expression );

                                    boolean_value = GetBooleanValue( replaced_expression );
                                }

                                condition_array ~= new CONDITION( boolean_value, boolean_value );
                                indentation -= 4;
                            }
                        }
                    }
                    else if ( command_name == "#elseif" )
                    {
                        if ( !condition_array[ condition_array.length - 1 ].ItWasTrue )
                        {
                            if ( command_expression == "" )
                            {
                                Abort( "Missing argument", stripped_line, file_path, line_index );
                            }
                            else
                            {
                                replaced_expression = context.ReplaceVariableNames( command_expression );

                                boolean_value = GetBooleanValue( replaced_expression );

                                condition_array[ $ - 1 ] = new CONDITION( boolean_value, boolean_value );
                            }
                        }
                        else
                        {
                            condition_array[ $ - 1 ].ItIsTrue = false;
                        }
                    }
                    else if ( stripped_line == "#else" )
                    {
                        if ( !condition_array[ $ - 1 ].ItWasTrue )
                        {
                            condition_array[ $ - 1 ] = new CONDITION( true, true );
                        }
                        else
                        {
                            condition_array[ $ - 1 ].ItIsTrue = false;
                        }
                    }
                    else if ( stripped_line == "#end" )
                    {
                        condition_array = condition_array[ 0 .. $ - 1 ];
                        indentation += 4;
                    }

                    line_is_ignored = true;
                }
                else
                {
                    if ( !line_is_ignored )
                    {
                        line_array[ line_index ] = context.ReplaceVariableNames( line );
                    }
                }
            }
            else
            {
                if ( !line_is_ignored )
                {
                    line_array[ line_index ] = context.ReplaceVariableNames( line );
                }
            }
        }

        if ( line_is_ignored )
        {
            line_array = line_array[ 0 .. line_index ] ~ line_array[ line_index + 1 .. $ ];
            indentation_array = indentation_array[ 0 .. line_index ] ~ indentation_array[ line_index + 1 .. $ ];
            --line_index;
        }
        else
        {
            indentation_array[ line_index ] += indentation;
        }
    }
}

// ~~

void IndentLineArray(
    ref string[] line_array,
    ref int[] indentation_array
    )
{
    foreach ( line_index; 0 .. indentation_array.length )
    {
        line_array[ line_index ]
            = FixIndentation( line_array[ line_index ], indentation_array[ line_index ] );
    }
}

// ~~

void JoinLineArray(
    ref string[] line_array
    )
{
    char
        line_first_character,
        line_last_character,
        next_line_first_character;
    int
        line_index;
    string
        line,
        line_first_characters,
        next_stripped_line,
        prior_stripped_line,
        stripped_line;

    line_index = 0;

    while ( line_index < line_array.length )
    {
        line = line_array[ line_index ];
        stripped_line = line.strip();

        if ( stripped_line != "" )
        {
            line_first_character = stripped_line[ 0 ];

            if ( stripped_line.length >= 2 )
            {
                line_first_characters = stripped_line[ 0 .. 2 ];
            }
            else
            {
                line_first_characters = stripped_line[ 0 .. 1 ];
            }

            line_last_character = stripped_line[ $ - 1 ];

            if ( line_index > 0
                 && "{)]+-*/%&|^<>=!:.".indexOf( line_first_character ) >= 0
                 && line_first_characters != "--"
                 && line_first_characters != "++"
                 && line_first_characters != "/*"
                 && line_first_characters != "*/"
                 && line_first_characters != "//" )
            {
                prior_stripped_line = stripRight( line_array[ line_index - 1 ] );

                if ( !HasEndingComment( prior_stripped_line ) )
                {
                    line_array[ line_index - 1 ] = prior_stripped_line ~ " " ~ stripped_line;
                    line_array = line_array[ 0 .. line_index ] ~ line_array[ line_index + 1 .. $ ];

                    --line_index;

                    continue;
                }
            }

            if ( line_index + 1 < line_array.length )
            {
                next_stripped_line = line_array[ line_index + 1 ].strip();

                if ( next_stripped_line.length > 0 )
                {
                    next_line_first_character = next_stripped_line[ 0 ];
                }
                else
                {
                    next_line_first_character = 0;
                }

                if ( "([,".indexOf( line_last_character ) >= 0
                     || ( line_first_characters != "//"
                          && "};,".indexOf( line_last_character ) < 0
                          && next_line_first_character == '}' )
                     || stripped_line == "return"
                     || ( stripped_line == "}"
                          && ( next_stripped_line == "else"
                               || next_stripped_line.startsWith( "else " ) ) ) )
                {
                    stripped_line = stripRight( line_array[ line_index ] );

                    if ( !HasEndingComment( stripped_line ) )
                    {
                        line_array[ line_index ] = stripped_line ~ " " ~ next_stripped_line;
                        line_array = line_array[ 0 .. line_index + 1 ] ~ line_array[ line_index + 2 .. $ ];

                        continue;
                    }
                }
            }
        }

        ++line_index;
    }
}

// ~~

void CleanLineArray(
    ref string[] line_array
    )
{
    int
        line_index;

    for ( line_index = 0;
          line_index < line_array.length;
          ++line_index )
    {
        line_array[ line_index ] = line_array[ line_index ].stripRight();
    }

    for ( line_index = 0;
          line_index < line_array.length - 1;
          ++line_index )
    {
        if ( line_array[ line_index ] == ""
             && ( line_index == 0
                  || line_array[ line_index + 1 ] == "" ) )
        {
            line_array = line_array[ 0 .. line_index ] ~ line_array[ line_index + 1 .. $ ];

            --line_index;
        }
    }
}

// .. APPLICATION

void ProcessFile(
    string file_path
    )
{
    bool
        file_has_changed;
    int[]
        indentation_array;
    string
        file_text,
        old_processed_file_text,
        processed_file_path,
        processed_file_text;
    string[]
        line_array;
    CONTEXT
        context;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Processing file : ", file_path );
    }

    file_text = file_path.readText();

    line_array = file_text.split( "\n" );
    indentation_array = GetIndentationArray( line_array, 0 );

    context = new CONTEXT;
    context.GlobalContext = context;
    context.IncludedFilePathArray = [ file_path ];

    ProcessLineArray(
        line_array,
        indentation_array,
        file_path,
        [],
        context,
        0
        );

    IndentLineArray( line_array, indentation_array );

    if ( JoinLinesOptionIsEnabled )
    {
        JoinLineArray( line_array );
    }

    CleanLineArray( line_array );

    processed_file_path = file_path[ 0 .. $ - InputExtension.length ] ~ OutputExtension;
    processed_file_path = ReplaceFolderPath( processed_file_path, InputFolderPath, OutputFolderPath );

    processed_file_text = line_array.join( "\n" );

    file_has_changed = true;

    if ( processed_file_path.exists() )
    {
        old_processed_file_text = processed_file_path.readText();

        if ( processed_file_text == old_processed_file_text )
        {
            file_has_changed = false;
        }
    }

    if ( file_has_changed )
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "Updating file : ", processed_file_path );
        }

        processed_file_path.write( processed_file_text );
    }
    else
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "Keeping file : ", processed_file_path );
        }
    }
}

// ~~

void ProcessFolder(
    string folder_path
    )
{
    if ( VerboseOptionIsEnabled )
    {
        writeln( "Processing folder : ", folder_path );
    }

    foreach (
        folder_entry;
        dirEntries(
            folder_path,
            InputFilter ~ InputExtension,
            RecursiveOptionIsEnabled ? SpanMode.breadth : SpanMode.shallow
            )
        )
    {
        ProcessFile( folder_entry.name() );
    }
}

// ~~

bool CheckArguments(
    string[] argument_array
    )
{
    string
        option,
        value;

    InputFilter = "*";
    InputExtension = ".gp";
    OutputExtension = ".go";
    InputFolderPath = ".";
    OutputFolderPath = "=";
    RecursiveOptionIsEnabled = false;
    JoinLinesOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;
    DebugOptionIsEnabled = false;
    FatalOptionIsEnabled = false;

    while ( argument_array.length > 0
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];
        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--input_filter"
             && argument_array.length > 0 )
        {
            InputFilter = argument_array[ 0 ];
            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--input_folder"
                  && argument_array.length > 0 )
        {
            InputFolderPath = argument_array[ 0 ];
            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--output_folder"
                  && argument_array.length > 0 )
        {
            OutputFolderPath = argument_array[ 0 ];
            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--recursive" )
        {
            RecursiveOptionIsEnabled = true;
        }
        else if ( option == "--join_lines" )
        {
            JoinLinesOptionIsEnabled = true;
        }
        else if ( option == "--verbose" )
        {
            VerboseOptionIsEnabled = true;
        }
        else if ( option == "--debug" )
        {
            DebugOptionIsEnabled = true;
        }
        else if ( option == "--fatal" )
        {
            FatalOptionIsEnabled = true;
        }
        else 
        {
            Abort( "Invalid option : " ~ option );

            return false;
        }
    }

    if ( OutputFolderPath == "=" )
    {
        OutputFolderPath = InputFolderPath;
    }

    InputFolderPath = GetNormalizedPath( InputFolderPath );
    OutputFolderPath = GetNormalizedPath( OutputFolderPath );
    
    if ( argument_array.length != 2 )
    {
        Abort( "Invalid arguments" );

        return false;
    }
    
    InputExtension = argument_array[ 0 ];
    OutputExtension = argument_array[ 1 ];

    return true;
}

// ~~

void main(
    string[] argument_array
    )
{
    if ( CheckArguments( argument_array[ 1 .. $ ] ) )
    {
        ProcessFolder( InputFolderPath );
    }
    else
    {
        writeln( "Usage : genesis [options] {input_extension} {output_extension}" );
        writeln( "Options :" );
        writeln( "    --input_filter *" );
        writeln( "    --input_folder ." );
        writeln( "    --output_folder =" );
        writeln( "    --recursive" );
        writeln( "    --join_lines" );
        writeln( "    --verbose" );
        writeln( "    --debug" );
        writeln( "    --fatal" );
        writeln( "Sample :" );
        writeln( "    genesis --recursive --join_lines .gp .go" );
    }
}

