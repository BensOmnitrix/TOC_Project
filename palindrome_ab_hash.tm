states: q0,qSeekRightA,qSeekRightB,qMarkLeftA,qMarkLeftB,qBack,qCheckDone,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b,#
tape_alphabet: a,b,#,A,B,x,_
delta:
q0 a -> x R qSeekRightA
q0 b -> x R qSeekRightB
q0 # -> # R qCheckDone
q0 x -> x R q0
q0 A -> A R q0
q0 B -> B R q0
q0 _ -> _ S qrej
qSeekRightA a -> a R qSeekRightA
qSeekRightA b -> b R qSeekRightA
qSeekRightA x -> x R qSeekRightA
qSeekRightA # -> # R qSeekRightA
qSeekRightA A -> A R qSeekRightA
qSeekRightA B -> B R qSeekRightA
qSeekRightA _ -> _ L qMarkLeftA
qSeekRightB a -> a R qSeekRightB
qSeekRightB b -> b R qSeekRightB
qSeekRightB x -> x R qSeekRightB
qSeekRightB # -> # R qSeekRightB
qSeekRightB A -> A R qSeekRightB
qSeekRightB B -> B R qSeekRightB
qSeekRightB _ -> _ L qMarkLeftB
qMarkLeftA A -> A L qMarkLeftA
qMarkLeftA B -> B L qMarkLeftA
qMarkLeftA a -> A L qBack
qMarkLeftA b -> b S qrej
qMarkLeftA # -> # L qMarkLeftA
qMarkLeftA x -> x L qMarkLeftA
qMarkLeftB A -> A L qMarkLeftB
qMarkLeftB B -> B L qMarkLeftB
qMarkLeftB b -> B L qBack
qMarkLeftB a -> a S qrej
qMarkLeftB # -> # L qMarkLeftB
qMarkLeftB x -> x L qMarkLeftB
qBack a -> a L qBack
qBack b -> b L qBack
qBack A -> A L qBack
qBack B -> B L qBack
qBack x -> x L qBack
qBack # -> # L qBack
qBack _ -> _ R q0
qCheckDone A -> A R qCheckDone
qCheckDone B -> B R qCheckDone
qCheckDone x -> x R qCheckDone
qCheckDone _ -> _ S qacc
qCheckDone a -> a S qrej
qCheckDone b -> b S qrej
qCheckDone # -> # R qCheckDone
