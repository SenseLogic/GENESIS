#set a := 10
#print a
a

#set b := a + 1
#print b
b

#set c := ( ( a * 2 ) + ( b - 1 ) ) * 3
#print c
c

#set r := "The result is : " ~ ( ( ( SquareRoot 4 ) * 0.5 ) + 1 )
#print r
r

#set s = "   Hello world   "
#print s
s

#set s := "   Hello " ~ ( LowerCase "WORLD" ) ~ "   "
#print $s$
s

#set t $:= "***" ~ ( LowerCase ( Strip ( Replace $s$ "world" "you" ) ) ) ~ "***"
#print t
t

#set result := "Result = " ~ 2.5
#print result
result

#set value := SquareRoot 2
#print value
value

