states: q0,qScan,qCarry,qDone,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 0,1
tape_alphabet: 0,1,_
delta:
q0 0 -> 0 R qScan
q0 1 -> 1 R qScan
q0 _ -> 1 S qacc
qScan 0 -> 0 R qScan
qScan 1 -> 1 R qScan
qScan _ -> _ L qCarry
qCarry 1 -> 0 L qCarry
qCarry 0 -> 1 S qDone
qCarry _ -> 1 S qDone
qDone 0 -> 0 S qacc
qDone 1 -> 1 S qacc
qDone _ -> _ S qacc
