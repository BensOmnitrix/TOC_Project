states: q0,qMarkLeftA,qMarkLeftB,qSeekRightA,qSeekRightB,qCompareA,qCompareB,qReturn,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,_
delta:
q0 _ -> _ S qacc
q0 A -> A R q0
q0 B -> B R q0
q0 a -> A R qSeekRightA
q0 b -> B R qSeekRightB

qSeekRightA a -> a R qSeekRightA
qSeekRightA b -> b R qSeekRightA
qSeekRightA A -> A R qSeekRightA
qSeekRightA B -> B R qSeekRightA
qSeekRightA _ -> _ L qCompareA

qSeekRightB a -> a R qSeekRightB
qSeekRightB b -> b R qSeekRightB
qSeekRightB A -> A R qSeekRightB
qSeekRightB B -> B R qSeekRightB
qSeekRightB _ -> _ L qCompareB

qCompareA a -> A L qReturn
qCompareA b -> b S qrej
qCompareA A -> A L qCompareA
qCompareA B -> B L qCompareA
qCompareA _ -> _ S qacc

qCompareB b -> B L qReturn
qCompareB a -> a S qrej
qCompareB B -> B L qCompareB
qCompareB A -> A L qCompareB
qCompareB _ -> _ S qacc

qReturn a -> a L qReturn
qReturn b -> b L qReturn
qReturn A -> A R qCheck
qReturn B -> B R qCheck
qReturn _ -> _ R qCheck

qCheck a -> A R qSeekRightA
qCheck b -> B R qSeekRightB
qCheck A -> A R qCheck
qCheck B -> B R qCheck
qCheck _ -> _ S qacc

