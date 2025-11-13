# string_reversal_full.tm
states: q0,q1,q2,q3,q4,q6
start: q0
accept: q6
reject: q6
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,|,_
delta:
# q0: move right to find end of input, write separator |
q0 a -> a R q0
q0 b -> b R q0
q0 _ -> | L q1

# q1: scan left to find rightmost unmarked char, mark it, scan right to verify
q1 a -> A R q2
q1 b -> B R q3
q1 A -> A L q1
q1 B -> B L q1
q1 | -> | L q1
q1 _ -> _ S q6

# q2: marked 'a' as 'A', scan right through marked chars, when hit |, write 'a' to output
q2 a -> a L q1
q2 b -> b L q1
q2 A -> A R q2
q2 B -> B R q2
q2 | -> | R q2out

# q3: marked 'b' as 'B', scan right through marked chars, when hit |, write 'b' to output
q3 a -> a L q1
q3 b -> b L q1
q3 A -> A R q3
q3 B -> B R q3
q3 | -> | R q3out

# q2out: skip past | to output area and write 'a'
q2out a -> a R q2out
q2out b -> b R q2out
q2out _ -> a L q4

# q3out: skip past | to output area and write 'b'
q3out a -> a R q3out
q3out b -> b R q3out
q3out _ -> b L q4

# q4: move left to find start and return to q1
q4 a -> a L q4
q4 b -> b L q4
q4 A -> A L q4
q4 B -> B L q4
q4 | -> | L q1
q4 _ -> _ R q1

# q6: accept state