# palindrome_nosep_full.tm
states: q0,qMarkLeftA,qMarkLeftB,qSeekRightA,qSeekRightB,qCompareA,qCompareB,qReturn,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,_
delta:
# initial: if blank => empty string -> accept
q0 _ -> _ S qacc
# find first unmarked: if 'a' mark and seek match, if 'b' mark and seek match, if marked keep scanning
q0 A -> A R q0
q0 B -> B R q0
q0 a -> A R qSeekRightA
q0 b -> B R qSeekRightB

# Seek rightmost unmarked (move right skipping marked until blank, then step left to last symbol)
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

# Compare states: if same symbol as left mark (a for A, b for B) then mark right and return; else reject
qCompareA a -> A L qReturn
qCompareA b -> b S qrej
qCompareA A -> A L qReturn   # corner: if we land on A that corresponds to same position (odd-length center) -> mark and return
qCompareA B -> B S qrej

qCompareB b -> B L qReturn
qCompareB a -> a S qrej
qCompareB B -> B L qReturn
qCompareB A -> A S qrej

# Return: move left until we hit first mark (A/B) position's right neighbor and resume q0
qReturn a -> a L qReturn
qReturn b -> b L qReturn
qReturn A -> A R q0
qReturn B -> B R q0
qReturn _ -> _ R q0

# qCheck not used separately; accept condition handled when q0 sees only blanks/marks
