states: q0,qInitReturn,qMarkCopy,qMoveToEndA,qMoveToEndB,qReturn,qacc
start: q0
accept: qacc
reject: qacc
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,|,_
delta:
q0 a -> a R q0
q0 b -> b R q0
q0 _ -> | L qInitReturn
qInitReturn a -> a L qInitReturn
qInitReturn b -> b L qInitReturn
qInitReturn _ -> _ R qMarkCopy
qMarkCopy A -> A R qMarkCopy
qMarkCopy B -> B R qMarkCopy
qMarkCopy a -> A R qMoveToEndA
qMarkCopy b -> B R qMoveToEndB
qMarkCopy | -> | S qacc
qMoveToEndA a -> a R qMoveToEndA
qMoveToEndA b -> b R qMoveToEndA
qMoveToEndA A -> A R qMoveToEndA
qMoveToEndA B -> B R qMoveToEndA
qMoveToEndA | -> | R qMoveToEndA
qMoveToEndA _ -> a L qReturn
qMoveToEndB a -> a R qMoveToEndB
qMoveToEndB b -> b R qMoveToEndB
qMoveToEndB A -> A R qMoveToEndB
qMoveToEndB B -> B R qMoveToEndB
qMoveToEndB | -> | R qMoveToEndB
qMoveToEndB _ -> b L qReturn
qReturn a -> a L qReturn
qReturn b -> b L qReturn
qReturn A -> A R qMarkCopy
qReturn B -> B R qMarkCopy
qReturn | -> | L qReturn
qReturn _ -> _ R qMarkCopy