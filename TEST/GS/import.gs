package main;

#import stack.gi

#call ImplementStack, int

// ~~

var
    first_stack intStack,
    second_stack stack[ int ];

// ~~

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

// ~~

func GetOtherResult(
    first_integer int,
    second_integer int,
    third_integer int,
    fourth_integer int
    ) int
{
    var
        an_integer : int,
        a_string : string;

    if first_integer < second_integer
       || third_integer > fourth_integer
    {
        return
            first_integer * 2
            - second_integer * 4
            + third_integer * 6
            - fourth_integer * 8;
    }
    else
    {
        return
            GetResult(
                first_integer,
                second_integer,
                third_integer,
                fourth_integer
                )
            + GetResult(
                first_integer + second_integer,
                second_integer + third_integer,
                third_integer + fourth_integer,
                fourth_integer + first_integer
                );
    }
}

// ~~

func TestPointers(
    pointer * TYPE
    )
{
    *pointer = new( TYPE );
    if ( pointer != nil )
    {
        *pointer = new( TYPE );
        *pointer = new( TYPE );

        *pointer = new( TYPE );
        // comment
        *pointer = new( TYPE );
    }
    *pointer = new( TYPE );
}

// ~~

func main()
{
}
