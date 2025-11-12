# unary_add_full.tm
states: q0,qFindSep,qMoveRight,qEraseRight,qBackToLeft,qAppend,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 1,0
tape_alphabet: 1,0,X,_,#
delta:
# Phase: find separator 0 between two unary blocks
q0 1 -> 1 R q0
q0 0 -> 0 R qFindSep
q0 _ -> _ S qrej

# Move right past separator into right block (position at first symbol of right block or blank)
qFindSep 1 -> 1 R qMoveRight
qFindSep _ -> _ S qCheck

# qMoveRight: if there's a 1 in right block, erase it (turn to _) and go back to left to append one
qMoveRight 1 -> _ L qBackToLeft
qMoveRight _ -> _ L qCheck

# qBackToLeft: go left until you reach separator (0)
qBackToLeft 1 -> 1 L qBackToLeft
qBackToLeft 0 -> 0 L qAppend
qBackToLeft X -> X L qBackToLeft
qBackToLeft _ -> _ L qBackToLeft

# qAppend: convert separator 0 -> 1 (effectively move one unary from right to left),
# then move right to resume erasing right block
qAppend 1 -> 1 S qrej
qAppend 0 -> 1 R qFindSep    # turned separator into 1, move right to process next right-1
qAppend X -> X S qrej

# qCheck: check if any 1 remains to right of separator; if none, convert any leftover separator to blank and accept
qCheck 1 -> 1 R qEraseRight   # found stray 1 on right -> remove in erase mode
qCheck 0 -> _ S qacc          # no right 1s, remove separator and accept
qCheck _ -> _ S qacc

# qEraseRight: erase remaining 1s and move back to check
qEraseRight 1 -> _ R qEraseRight
qEraseRight _ -> _ L qBackToLeft
qEraseRight 0 -> 0 S qrej
