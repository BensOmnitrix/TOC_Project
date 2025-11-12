# equal_abcs_full.tm
states: q0,qMarkA,qSeekB,qMarkB,qSeekC,qMarkC,qReturn,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b,c
tape_alphabet: a,b,c,X,Y,Z,_
delta:
# q0: find first unmarked 'a' to mark, skip marks
q0 a -> X R qSeekB
q0 X -> X R q0
q0 Y -> Y R q0
q0 Z -> Z R q0
q0 _ -> _ S qCheck

# qSeekB: move right to find first unmarked 'b'
qSeekB a -> a R qSeekB
qSeekB X -> X R qSeekB
qSeekB b -> Y R qSeekC
qSeekB Y -> Y R qSeekB
qSeekB Z -> Z R qSeekB
qSeekB _ -> _ S qrej

# qSeekC: move right to find first unmarked 'c'
qSeekC b -> b R qSeekC
qSeekC Y -> Y R qSeekC
qSeekC c -> Z L qReturn
qSeekC Z -> Z R qSeekC
qSeekC _ -> _ S qrej

# qReturn: return to leftmost to find next 'a'
qReturn a -> a L qReturn
qReturn b -> b L qReturn
qReturn c -> c L qReturn
qReturn X -> X R q0
qReturn Y -> Y L qReturn
qReturn Z -> Z L qReturn
qReturn _ -> _ R q0

# qCheck: scan for any unmarked a/b/c, if none accept, else reject
qCheck X -> X R qCheck
qCheck Y -> Y R qCheck
qCheck Z -> Z R qCheck
qCheck _ -> _ S qacc
qCheck a -> a S qrej
qCheck b -> b S qrej
qCheck c -> c S qrej
