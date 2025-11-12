# string_reversal_full.tm
states: q0,qScanRight,qFindRightUnmarked,qMarkRightmost,qMoveToEnd,qWrite, qBackToSource,qCheck,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b
tape_alphabet: a,b,A,B,|,_,#
delta:
# q0: move to rightmost end to prepare a marker (delimiter)
q0 a -> a R q0
q0 b -> b R q0
q0 _ -> _ L qScanRight

# qScanRight: step left to find first unmarked (a or b)
qScanRight a -> a L qScanRight
qScanRight b -> b L qScanRight
qScanRight A -> A L qScanRight
qScanRight B -> B L qScanRight
qScanRight _ -> _ R qFindRightUnmarked

# qFindRightUnmarked: move right to find rightmost unmarked (the loop chooses rightmost by scanning until blank and stepping left)
qFindRightUnmarked a -> a R qFindRightUnmarked
qFindRightUnmarked b -> b R qFindRightUnmarked
qFindRightUnmarked A -> A R qFindRightUnmarked
qFindRightUnmarked B -> B R qFindRightUnmarked
qFindRightUnmarked _ -> _ L qMarkRightmost

# qMarkRightmost: mark the rightmost unmarked as A/B, remember symbol by state, then go to end to write
qMarkRightmost a -> A L qBackToSource
qMarkRightmost b -> B L qBackToSource
qMarkRightmost A -> A L qBackToSource
qMarkRightmost B -> B L qBackToSource

# qBackToSource: move left to the leftmost delimiter (we'll find a blank left of original string to use as write area)
qBackToSource a -> a L qBackToSource
qBackToSource b -> b L qBackToSource
qBackToSource A -> A L qBackToSource
qBackToSource B -> B L qBackToSource
qBackToSource _ -> _ R qMoveToEnd

# qMoveToEnd: move right to find the first blank after original string (that will be writing zone)
qMoveToEnd a -> a R qMoveToEnd
qMoveToEnd b -> b R qMoveToEnd
qMoveToEnd A -> A R qMoveToEnd
qMoveToEnd B -> B R qMoveToEnd
qMoveToEnd _ -> | R qWrite   # place a delimiter '|' then write copy symbol

# qWrite: write the symbol based on the marked symbol we left behind (we determine by scanning left and finding last A/B)
# To simplify, when we arrived to write, the last unread marked symbol is either A or B nearest left; we write appropriate letter at current cell.
qWrite _ -> _ L qCheck   # placeholder (we'll actually write by stepping back to find the A/B and writing from there)
# Practical approach for single-tape TM: instead we will re-find the marked symbol: go left to find A/B, record symbol by state,
# return to delimiter area and write actual letter. Implemented as follows:

# Instead of qWrite above, we do:
qMoveToEnd | -> | R qWrite

# qWrite: if we see blank, we must determine which marked symbol is waiting. We'll search left for A or B, remember and write.
qWrite _ -> _ L qFindMarkToCopy
qWrite a -> a R qWrite
qWrite b -> b R qWrite
qWrite A -> A R qWrite
qWrite B -> B R qWrite
qWrite | -> | R qWrite

# qFindMarkToCopy: go left until find A or B, then set state to write appropriate symbol
qFindMarkToCopy A -> A R qReturnWriteA
qFindMarkToCopy B -> B R qReturnWriteB
qFindMarkToCopy a -> a L qFindMarkToCopy
qFindMarkToCopy b -> b L qFindMarkToCopy
qFindMarkToCopy _ -> _ L qFindMarkToCopy

# qReturnWriteA: move right to delimiter area and write 'a'
qReturnWriteA a -> a R qReturnWriteA
qReturnWriteA b -> b R qReturnWriteA
qReturnWriteA A -> A R qReturnWriteA
qReturnWriteA B -> B R qReturnWriteA
qReturnWriteA | -> | R qPutA
qReturnWriteA _ -> _ R qReturnWriteA

# qPutA: write 'a' at current blank and return left to continue
qPutA _ -> a L qScanRight

# qReturnWriteB: symmetrical for 'b'
qReturnWriteB a -> a R qReturnWriteB
qReturnWriteB b -> b R qReturnWriteB
qReturnWriteB A -> A R qReturnWriteB
qReturnWriteB B -> B R qReturnWriteB
qReturnWriteB | -> | R qPutB
qReturnWriteB _ -> _ R qReturnWriteB

qPutB _ -> b L qScanRight

# qCheck: after writing, check if any unmarked left remains; if only marks exist, accept
qCheck A -> A R qCheck
qCheck B -> B R qCheck
qCheck a -> a S qScanRight
qCheck b -> b S qScanRight
qCheck _ -> _ S qacc
