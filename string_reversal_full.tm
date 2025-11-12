# string_reversal_full.tm
states: q0,qScanRight,qFindRightUnmarked,qScanUnmarked,qCheckDone,qMarkRightmost,qBackToSourceA,qBackToSourceB,qMoveToEndA,qMoveToEndB,qSkipOutputA,qSkipOutputB,qacc,qrej
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
qScanRight | -> | L qScanRight
qScanRight _ -> _ R qFindRightUnmarked

# qFindRightUnmarked: move right through marked chars, when hit unmarked continue to find last unmarked
qFindRightUnmarked A -> A R qFindRightUnmarked
qFindRightUnmarked B -> B R qFindRightUnmarked
qFindRightUnmarked a -> a R qScanUnmarked
qFindRightUnmarked b -> b R qScanUnmarked
qFindRightUnmarked | -> | L qCheckDone
qFindRightUnmarked _ -> | L qCheckDone

# qScanUnmarked: continue right through unmarked to find rightmost
qScanUnmarked a -> a R qScanUnmarked
qScanUnmarked b -> b R qScanUnmarked
qScanUnmarked A -> A L qMarkRightmost
qScanUnmarked B -> B L qMarkRightmost
qScanUnmarked | -> | L qMarkRightmost
qScanUnmarked _ -> | L qMarkRightmost

# qCheckDone: check if any unmarked chars exist, if not accept
qCheckDone A -> A L qCheckDone
qCheckDone B -> B L qCheckDone
qCheckDone a -> a S qMarkRightmost
qCheckDone b -> b S qMarkRightmost
qCheckDone _ -> _ S qacc

# qMarkRightmost: mark the rightmost unmarked as A/B, REMEMBER by transitioning to different states
qMarkRightmost a -> A L qBackToSourceA
qMarkRightmost b -> B L qBackToSourceB

# qBackToSourceA: marked an 'a', now go back to start
qBackToSourceA a -> a L qBackToSourceA
qBackToSourceA b -> b L qBackToSourceA
qBackToSourceA A -> A L qBackToSourceA
qBackToSourceA B -> B L qBackToSourceA
qBackToSourceA _ -> _ R qMoveToEndA

# qBackToSourceB: marked a 'b', now go back to start
qBackToSourceB a -> a L qBackToSourceB
qBackToSourceB b -> b L qBackToSourceB
qBackToSourceB A -> A L qBackToSourceB
qBackToSourceB B -> B L qBackToSourceB
qBackToSourceB _ -> _ R qMoveToEndB

# qMoveToEndA: move to output area to write 'a'
qMoveToEndA a -> a R qMoveToEndA
qMoveToEndA b -> b R qMoveToEndA
qMoveToEndA A -> A R qMoveToEndA
qMoveToEndA B -> B R qMoveToEndA
qMoveToEndA | -> | R qSkipOutputA
qMoveToEndA _ -> | R qSkipOutputA

# qMoveToEndB: move to output area to write 'b'
qMoveToEndB a -> a R qMoveToEndB
qMoveToEndB b -> b R qMoveToEndB
qMoveToEndB A -> A R qMoveToEndB
qMoveToEndB B -> B R qMoveToEndB
qMoveToEndB | -> | R qSkipOutputB
qMoveToEndB _ -> | R qSkipOutputB

# qSkipOutputA: skip existing output characters to find blank, then write 'a'
qSkipOutputA a -> a R qSkipOutputA
qSkipOutputA b -> b R qSkipOutputA
qSkipOutputA _ -> a L qScanRight

# qSkipOutputB: skip existing output characters to find blank, then write 'b'
qSkipOutputB a -> a R qSkipOutputB
qSkipOutputB b -> b R qSkipOutputB
qSkipOutputB _ -> b L qScanRight
