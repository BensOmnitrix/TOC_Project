# unary_add_full.tm
states: q0,qSeekRight,qEraseRight,qBackToSep,qPrepend,qBackToStart,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 1,0
tape_alphabet: 1,0,_
delta:
# q0: scan right through left block to separator
q0 1 -> 1 R q0
q0 0 -> 0 R qSeekRight
q0 _ -> _ S qrej

# qSeekRight: scan right through right block to find rightmost 1
qSeekRight 1 -> 1 R qSeekRight
qSeekRight 0 -> 0 R qSeekRight
qSeekRight _ -> _ L qEraseRight

# qEraseRight: erase rightmost 1 from right block, or check if done
qEraseRight 1 -> _ L qBackToSep
qEraseRight 0 -> 0 S qCheck
qEraseRight _ -> _ R qCheck

# qBackToSep: move left to find the separator
qBackToSep 1 -> 1 L qBackToSep
qBackToSep _ -> _ L qBackToSep
qBackToSep 0 -> 0 L qPrepend

# qPrepend: position before separator, add a 1 to left block
qPrepend 1 -> 1 L qPrepend
qPrepend 0 -> 0 L qPrepend
qPrepend _ -> 1 R qBackToStart

# qBackToStart: go back to leftmost position to restart loop
qBackToStart 1 -> 1 L qBackToStart
qBackToStart 0 -> 0 L qBackToStart
qBackToStart _ -> _ R q0

# qCheck: all 1s from right moved, remove separator and accept
qCheck 0 -> _ S qacc
qCheck _ -> _ S qacc
qCheck 1 -> 1 S qrej
