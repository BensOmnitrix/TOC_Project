# unary_add_full.tm - Minimal state unary addition
states: q0,q1,q2,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 1,0
tape_alphabet: 1,0,_
delta:
# q0: scan right through 1s, convert separator 0 to 1
q0 1 -> 1 R q0
q0 0 -> 1 R q1
q0 _ -> _ S qrej

# q1: scan right through 1s to end
q1 1 -> 1 R q1
q1 _ -> _ L q2
q1 0 -> 0 S qrej

# q2: erase rightmost 1 and accept
q2 1 -> _ L qacc
q2 _ -> _ S qrej
q2 0 -> 0 S qrej
