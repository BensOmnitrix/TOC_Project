states: qInit,qInitReturn,q0,qMoveToEndA,qMoveToEndB,qReturn,qacc,qrej
start: qInit
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,|,_
delta:
qInit a -> a R qInit
qInit b -> b R qInit
qInit _ -> | L qInitReturn
qInitReturn a -> a L qInitReturn
qInitReturn b -> b L qInitReturn
qInitReturn _ -> _ R q0
q0 _ -> _ R q0
q0 a -> A R qMoveToEndA
q0 b -> B R qMoveToEndB
q0 A -> A R q0
q0 B -> B R q0
q0 | -> | S qacc
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
qReturn A -> A L qReturn
qReturn B -> B L qReturn
qReturn | -> | L qReturn
qReturn _ -> _ R q0
