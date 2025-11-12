# binary_addition_full.tm
# Single-tape TM for binary addition: input x#y (MSB left), outputs sum z replacing y and erases x and '#'
# Symbols used: 0,1,#,_ (blank), X=processed-0-from-x, Y=processed-1-from-x, M=marker-for-y-cell
# States encode control + carry when necessary
states:
    q_start, q_seek_end, q_at_end,
    q_process_y,                # read current y bit and mark its cell M; y_bit encoded in next state
    q_y0_marked, q_y1_marked,   # y bit was 0 or 1 (we call these after writing M)
    q_move_to_hash,              # move left to find '#'
    q_find_x_bit0, q_find_x_bit1, q_no_x_bit, # results of finding x bit (0/1/none)
    q_compute_c0_x0y0, q_compute_c0_x0y1, q_compute_c0_x1y0, q_compute_c0_x1y1,
    q_compute_c1_x0y0, q_compute_c1_x0y1, q_compute_c1_x1y0, q_compute_c1_x1y1,
    q_write0_c0, q_write1_c0, q_write0_c1, q_write1_c1,
    q_return_to_M,               # go right to find M and write result
    q_find_next_y, q_skip_hash_to_leftmost_unproc_x,
    q_process_remaining_x_c0, q_process_remaining_x_c1,
    q_write_final_carry, q_cleanup_left, q_done, q_reject
start: q_start
accept: q_done
reject: q_reject
blank: _
input_alphabet: 0,1,#
tape_alphabet: 0,1,#,_,X,Y,M

delta:
# -------------------------------
# q_start: move right to find the rightmost non-blank cell (end of tape)
# -------------------------------
q_start 0 -> 0 R q_start
q_start 1 -> 1 R q_start
q_start # -> # R q_start
q_start _ -> _ L q_seek_end

# -------------------------------
# q_seek_end: step left to the last symbol before blank (rightmost written symbol)
# -------------------------------
q_seek_end 0 -> 0 L q_seek_end
q_seek_end 1 -> 1 L q_seek_end
q_seek_end # -> # L q_seek_end
# if we step left into blank (shouldn't), go to at_end handler
q_seek_end _ -> _ R q_at_end

# q_at_end: now position is on rightmost symbol (LSB of y). Start processing loop with carry=0
q_at_end 0 -> 0 S q_process_y
q_at_end 1 -> 1 S q_process_y
q_at_end # -> # S q_process_y   # y may be empty; handle in process_y
q_at_end X -> X S q_process_y
q_at_end Y -> Y S q_process_y

# -------------------------------
# q_process_y: read current cell (y bit). If 0/1 mark it M and branch storing bit info in state
# If at '#' (no more y bits) go to handle y exhausted
# -------------------------------
q_process_y 0 -> M R q_y0_marked
q_process_y 1 -> M R q_y1_marked
q_process_y X -> X S q_skip_hash_to_leftmost_unproc_x  # y cell is already overwritten (possible when continuing) -> go find next
q_process_y Y -> Y S q_skip_hash_to_leftmost_unproc_x
q_process_y # -> # S q_skip_hash_to_leftmost_unproc_x
q_process_y _ -> _ S q_skip_hash_to_leftmost_unproc_x

# -------------------------------
# After marking M, move left to find corresponding x bit (to add)
# q_y0_marked and q_y1_marked represent we saw y=0 or y=1 (with carry determined later)
# -------------------------------
q_y0_marked 0 -> 0 L q_move_to_hash
q_y0_marked 1 -> 1 L q_move_to_hash
q_y0_marked # -> # L q_move_to_hash
q_y0_marked X -> X L q_move_to_hash
q_y0_marked Y -> Y L q_move_to_hash

q_y1_marked 0 -> 0 L q_move_to_hash
q_y1_marked 1 -> 1 L q_move_to_hash
q_y1_marked # -> # L q_move_to_hash
q_y1_marked X -> X L q_move_to_hash
q_y1_marked Y -> Y L q_move_to_hash

# q_move_to_hash: keep moving left until we reach '#' (separator)
q_move_to_hash 0 -> 0 L q_move_to_hash
q_move_to_hash 1 -> 1 L q_move_to_hash
q_move_to_hash X -> X L q_move_to_hash
q_move_to_hash Y -> Y L q_move_to_hash
q_move_to_hash # -> # L q_find_x_bit0   # step left to inspect x-bit (maybe blank)

# q_find_x_bit0: we are to left of '#' — look at cell: if 0/1 => we found x-bit, otherwise blank/marker => no x-bit (treat as 0)
q_find_x_bit0 0 -> X R q_compute_c0_x0y0   # we found x=0, mark as processed X and compute (assume carry=0 path)
q_find_x_bit0 1 -> Y R q_compute_c0_x1y0   # found x=1, mark Y
q_find_x_bit0 X -> X R q_compute_c0_no_x   # processed before -> treat as no x (0)
q_find_x_bit0 Y -> Y R q_compute_c0_no_x
q_find_x_bit0 _ -> _ R q_compute_c0_no_x

# NOTE: above we assumed carry=0; but we actually need to track carry. To do that cleanly we will branch from q_find_x_bit... depending on prior carry.
# For simplicity we will unify: when we left the y-cell, we don't yet know carry. Instead we will implement two subflows:
# - The main loop will always assume carry=0 initially. We will implement carry handling by having separate compute states for carry0 and carry1.
# For that, rather than branching from q_find_x_bit0 into carry0 versus carry1 states, we must determine carryness before. To keep the machine deterministic and simpler:
# we will maintain carry implicitly in the state when we enter y-processing; initial carry=0; when carry=1 we use different states. So we must modify above transitions to include carry states.
# ----
# For correctness, below is the explicit complete carry-aware set of transitions. We will restart this carry-aware section now.

# -------------- REWRITE: carry-aware processing ---------------
# We'll use q_process_y_c0 and q_process_y_c1 as entry points when carry is 0 or 1.
# To simplify the file (and keep it deterministic), let's re-route from q_at_end to carry-0 handler q_process_y_c0.

# (we add duplicate transitions to handle carry=0 path from q_at_end)

# Redirect q_at_end to carry-0 main loop
q_at_end 0 -> 0 S q_process_y_c0
q_at_end 1 -> 1 S q_process_y_c0
q_at_end # -> # S q_skip_hash_to_leftmost_unproc_x
q_at_end X -> X S q_skip_hash_to_leftmost_unproc_x
q_at_end Y -> Y S q_skip_hash_to_leftmost_unproc_x

# Process y with carry = 0
q_process_y_c0 0 -> M R q_y0_marked_c0
q_process_y_c0 1 -> M R q_y1_marked_c0
q_process_y_c0 # -> # S q_skip_hash_to_leftmost_unproc_x
q_process_y_c0 _ -> _ S q_skip_hash_to_leftmost_unproc_x
q_process_y_c0 X -> X S q_skip_hash_to_leftmost_unproc_x
q_process_y_c0 Y -> Y S q_skip_hash_to_leftmost_unproc_x

# Process y with carry = 1 (only reached when carry previously set)
q_process_y_c1 0 -> M R q_y0_marked_c1
q_process_y_c1 1 -> M R q_y1_marked_c1
q_process_y_c1 # -> # S q_skip_hash_to_leftmost_unproc_x
q_process_y_c1 _ -> _ S q_skip_hash_to_leftmost_unproc_x
q_process_y_c1 X -> X S q_skip_hash_to_leftmost_unproc_x
q_process_y_c1 Y -> Y S q_skip_hash_to_leftmost_unproc_x

# Now two branches reading y bit and moving toward x; we will look for x bit and compute sum based on carry

# ---------------- Carry = 0 path ----------------
q_y0_marked_c0 0 -> 0 L q_move_to_hash_c0
q_y0_marked_c0 1 -> 1 L q_move_to_hash_c0
q_y0_marked_c0 X -> X L q_move_to_hash_c0
q_y0_marked_c0 Y -> Y L q_move_to_hash_c0
q_y0_marked_c0 # -> # L q_move_to_hash_c0
q_y0_marked_c0 _ -> _ L q_move_to_hash_c0

q_y1_marked_c0 0 -> 0 L q_move_to_hash_c0
q_y1_marked_c0 1 -> 1 L q_move_to_hash_c0
q_y1_marked_c0 X -> X L q_move_to_hash_c0
q_y1_marked_c0 Y -> Y L q_move_to_hash_c0
q_y1_marked_c0 # -> # L q_move_to_hash_c0
q_y1_marked_c0 _ -> _ L q_move_to_hash_c0

# Move left to '#'
q_move_to_hash_c0 0 -> 0 L q_move_to_hash_c0
q_move_to_hash_c0 1 -> 1 L q_move_to_hash_c0
q_move_to_hash_c0 X -> X L q_move_to_hash_c0
q_move_to_hash_c0 Y -> Y L q_move_to_hash_c0
q_move_to_hash_c0 # -> # L q_find_x_c0

# Find x when carry=0
# If we find an unprocessed x bit (0 or 1), mark it as processed (X or Y), then compute sum.
q_find_x_c0 0 -> X R q_compute_c0_x0y?   # placeholder to branch depending on which y we marked
q_find_x_c0 1 -> Y R q_compute_c0_x1y?
# If we find X or Y or blank, treat as no x-bit (x=0)
q_find_x_c0 X -> X R q_compute_c0_no_x
q_find_x_c0 Y -> Y R q_compute_c0_no_x
q_find_x_c0 _ -> _ R q_compute_c0_no_x

# We must know whether the y was 0 or 1; that's encoded by whether we came from q_y0_marked_c0 or q_y1_marked_c0.
# To implement this deterministically, instead of the generic q_find_x_c0, we should have two separate find states:
# q_find_x_after_y0_c0 and q_find_x_after_y1_c0

# So replace previous with explicit states:

# After y=0, carry=0:
q_y0_marked_c0 0 -> 0 L q_move_to_hash_after_y0_c0
q_y0_marked_c0 1 -> 1 L q_move_to_hash_after_y0_c0
q_y0_marked_c0 X -> X L q_move_to_hash_after_y0_c0
q_y0_marked_c0 Y -> Y L q_move_to_hash_after_y0_c0
q_y0_marked_c0 # -> # L q_move_to_hash_after_y0_c0
q_y0_marked_c0 _ -> _ L q_move_to_hash_after_y0_c0

q_y1_marked_c0 0 -> 0 L q_move_to_hash_after_y1_c0
q_y1_marked_c0 1 -> 1 L q_move_to_hash_after_y1_c0
q_y1_marked_c0 X -> X L q_move_to_hash_after_y1_c0
q_y1_marked_c0 Y -> Y L q_move_to_hash_after_y1_c0
q_y1_marked_c0 # -> # L q_move_to_hash_after_y1_c0
q_y1_marked_c0 _ -> _ L q_move_to_hash_after_y1_c0

q_move_to_hash_after_y0_c0 0 -> 0 L q_move_to_hash_after_y0_c0
q_move_to_hash_after_y0_c0 1 -> 1 L q_move_to_hash_after_y0_c0
q_move_to_hash_after_y0_c0 X -> X L q_move_to_hash_after_y0_c0
q_move_to_hash_after_y0_c0 Y -> Y L q_move_to_hash_after_y0_c0
q_move_to_hash_after_y0_c0 # -> # L q_find_x_after_y0_c0

q_move_to_hash_after_y1_c0 0 -> 0 L q_move_to_hash_after_y1_c0
q_move_to_hash_after_y1_c0 1 -> 1 L q_move_to_hash_after_y1_c0
q_move_to_hash_after_y1_c0 X -> X L q_move_to_hash_after_y1_c0
q_move_to_hash_after_y1_c0 Y -> Y L q_move_to_hash_after_y1_c0
q_move_to_hash_after_y1_c0 # -> # L q_find_x_after_y1_c0

# q_find_x_after_y0_c0: find x bit for y=0 and carry=0
q_find_x_after_y0_c0 0 -> X R q_compute_c0_x0y0
q_find_x_after_y0_c0 1 -> Y R q_compute_c0_x1y0
q_find_x_after_y0_c0 X -> X R q_compute_c0_no_x_y0
q_find_x_after_y0_c0 Y -> Y R q_compute_c0_no_x_y0
q_find_x_after_y0_c0 _ -> _ R q_compute_c0_no_x_y0

# q_find_x_after_y1_c0: find x bit for y=1 and carry=0
q_find_x_after_y1_c0 0 -> X R q_compute_c0_x0y1
q_find_x_after_y1_c0 1 -> Y R q_compute_c0_x1y1
q_find_x_after_y1_c0 X -> X R q_compute_c0_no_x_y1
q_find_x_after_y1_c0 Y -> Y R q_compute_c0_no_x_y1
q_find_x_after_y1_c0 _ -> _ R q_compute_c0_no_x_y1

# Compute outcomes for carry=0 cases:
# x y carry(0) -> result, newcarry
# 0 0 0 -> 0, c0
q_compute_c0_x0y0  ->  S q_write0_c0
# 1 0 0 -> 1, c0
q_compute_c0_x1y0  ->  S q_write1_c0
# no x (treat x=0) with y=0 -> same as x0y0
q_compute_c0_no_x_y0 -> S q_write0_c0

# x0y1 -> 1, c0
q_compute_c0_x0y1 -> S q_write1_c0
# x1y1 -> 0, c1 (since 1+1=0 carry1)
q_compute_c0_x1y1 -> S q_write0_c1
# no_x_y1 -> same as x0y1
q_compute_c0_no_x_y1 -> S q_write1_c0

# ---------------- Carry = 1 path ----------------
# mirrored structure but with carry=1 initial

q_y0_marked_c1 0 -> 0 L q_move_to_hash_after_y0_c1
q_y0_marked_c1 1 -> 1 L q_move_to_hash_after_y0_c1
q_y0_marked_c1 X -> X L q_move_to_hash_after_y0_c1
q_y0_marked_c1 Y -> Y L q_move_to_hash_after_y0_c1
q_y0_marked_c1 # -> # L q_move_to_hash_after_y0_c1
q_y0_marked_c1 _ -> _ L q_move_to_hash_after_y0_c1

q_y1_marked_c1 0 -> 0 L q_move_to_hash_after_y1_c1
q_y1_marked_c1 1 -> 1 L q_move_to_hash_after_y1_c1
q_y1_marked_c1 X -> X L q_move_to_hash_after_y1_c1
q_y1_marked_c1 Y -> Y L q_move_to_hash_after_y1_c1
q_y1_marked_c1 # -> # L q_move_to_hash_after_y1_c1
q_y1_marked_c1 _ -> _ L q_move_to_hash_after_y1_c1

q_move_to_hash_after_y0_c1 0 -> 0 L q_move_to_hash_after_y0_c1
q_move_to_hash_after_y0_c1 1 -> 1 L q_move_to_hash_after_y0_c1
q_move_to_hash_after_y0_c1 X -> X L q_move_to_hash_after_y0_c1
q_move_to_hash_after_y0_c1 Y -> Y L q_move_to_hash_after_y0_c1
q_move_to_hash_after_y0_c1 # -> # L q_find_x_after_y0_c1

q_move_to_hash_after_y1_c1 0 -> 0 L q_move_to_hash_after_y1_c1
q_move_to_hash_after_y1_c1 1 -> 1 L q_move_to_hash_after_y1_c1
q_move_to_hash_after_y1_c1 X -> X L q_move_to_hash_after_y1_c1
q_move_to_hash_after_y1_c1 Y -> Y L q_move_to_hash_after_y1_c1
q_move_to_hash_after_y1_c1 # -> # L q_find_x_after_y1_c1

q_find_x_after_y0_c1 0 -> X R q_compute_c1_x0y0
q_find_x_after_y0_c1 1 -> Y R q_compute_c1_x1y0
q_find_x_after_y0_c1 X -> X R q_compute_c1_no_x_y0
q_find_x_after_y0_c1 Y -> Y R q_compute_c1_no_x_y0
q_find_x_after_y0_c1 _ -> _ R q_compute_c1_no_x_y0

q_find_x_after_y1_c1 0 -> X R q_compute_c1_x0y1
q_find_x_after_y1_c1 1 -> Y R q_compute_c1_x1y1
q_find_x_after_y1_c1 X -> X R q_compute_c1_no_x_y1
q_find_x_after_y1_c1 Y -> Y R q_compute_c1_no_x_y1
q_find_x_after_y1_c1 _ -> _ R q_compute_c1_no_x_y1

# Compute outcomes for carry=1 cases:
# x y carry(1) -> result, newcarry
# 0 0 1 -> 1, c0
q_compute_c1_x0y0 -> S q_write1_c0
# 1 0 1 -> 0, c1 (1+0+1=0 carry1)
q_compute_c1_x1y0 -> S q_write0_c1
q_compute_c1_no_x_y0 -> S q_write1_c0

# 0 1 1 -> 0, c1 (0+1+1=0 carry1)
q_compute_c1_x0y1 -> S q_write0_c1
# 1 1 1 -> 1, c1? (1+1+1=1 carry1) -> result 1 carry1
q_compute_c1_x1y1 -> S q_write1_c1
q_compute_c1_no_x_y1 -> S q_write0_c1

# ----------------
# q_write* states: we now have computed the result bit and new carry; navigate right to marker M and write the result bit
# We'll map q_write0_c0: write 0, next carry=0 -> after writing go to q_return_to_M which then finds next y or handles remaining x/carry
# We use the same return state but encode carry in next state transitions.
# ----------------

# Because the transition format used by the parser requires exact tokens, below we add explicit transitions mapping these abstract q_* tags to concrete state names and actions.
# For readability we will replace the abstract annotations above with concrete transitions now.

# --- Concrete compute/write transitions (explicit) ---

# For brevity and to make this file loadable, we implement the final mapping as follows:
# When in any q_compute_* we immediately jump to a concrete state that remembers both result bit and next carry:
# e.g. q_compute_c0_x0y0  -> q_write0_next_c0

# Implement these mappings:

q_compute_c0_x0y0        _ -> _ S q_write0_next_c0
q_compute_c0_x1y0        _ -> _ S q_write1_next_c0
q_compute_c0_no_x_y0     _ -> _ S q_write0_next_c0
q_compute_c0_x0y1        _ -> _ S q_write1_next_c0
q_compute_c0_x1y1        _ -> _ S q_write0_next_c1
q_compute_c0_no_x_y1     _ -> _ S q_write1_next_c0

q_compute_c1_x0y0        _ -> _ S q_write1_next_c0
q_compute_c1_x1y0        _ -> _ S q_write0_next_c1
q_compute_c1_no_x_y0     _ -> _ S q_write1_next_c0
q_compute_c1_x0y1        _ -> _ S q_write0_next_c1
q_compute_c1_x1y1        _ -> _ S q_write1_next_c1
q_compute_c1_no_x_y1     _ -> _ S q_write0_next_c1

# q_write*_next_c* : now from any such state we must move right until we find M, write result bit, and then continue main loop with the next carry encoded

# write 0 and next carry 0
q_write0_next_c0 0 -> 0 R q_write0_next_c0
q_write0_next_c0 1 -> 1 R q_write0_next_c0
q_write0_next_c0 X -> X R q_write0_next_c0
q_write0_next_c0 Y -> Y R q_write0_next_c0
q_write0_next_c0 # -> # R q_write0_next_c0
q_write0_next_c0 M -> 0 R q_after_write_c0

# write 1 and next carry 0
q_write1_next_c0 0 -> 0 R q_write1_next_c0
q_write1_next_c0 1 -> 1 R q_write1_next_c0
q_write1_next_c0 X -> X R q_write1_next_c0
q_write1_next_c0 Y -> Y R q_write1_next_c0
q_write1_next_c0 # -> # R q_write1_next_c0
q_write1_next_c0 M -> 1 R q_after_write_c0

# write 0 and next carry 1
q_write0_next_c1 0 -> 0 R q_write0_next_c1
q_write0_next_c1 1 -> 1 R q_write0_next_c1
q_write0_next_c1 X -> X R q_write0_next_c1
q_write0_next_c1 Y -> Y R q_write0_next_c1
q_write0_next_c1 # -> # R q_write0_next_c1
q_write0_next_c1 M -> 0 R q_after_write_c1

# write 1 and next carry 1
q_write1_next_c1 0 -> 0 R q_write1_next_c1
q_write1_next_c1 1 -> 1 R q_write1_next_c1
q_write1_next_c1 X -> X R q_write1_next_c1
q_write1_next_c1 Y -> Y R q_write1_next_c1
q_write1_next_c1 # -> # R q_write1_next_c1
q_write1_next_c1 M -> 1 R q_after_write_c1

# After writing result bit, we are on the cell to the right of the written result; go find next unprocessed y bit to the left.
# q_after_write_c0 / q_after_write_c1: move left to find next y digit (0/1) that hasn't been overwritten
q_after_write_c0 0 -> 0 L q_after_write_c0
q_after_write_c0 1 -> 1 L q_after_write_c0
q_after_write_c0 X -> X L q_after_write_c0
q_after_write_c0 Y -> Y L q_after_write_c0
q_after_write_c0 # -> # L q_after_write_c0
q_after_write_c0 _ -> _ L q_after_write_c0
q_after_write_c0 M -> M L q_after_write_c0
# when we find a cell that is 0 or 1 and is a y cell (i.e., to the right of '#'), we will go to q_process_y_c0 if next carry is 0, or q_process_y_c1 if next carry is 1
# To detect region (right of #) vs left of # we step left until we find '#' then decide.
# But simpler: from any position after write, just move left until we find a 0/1 that is still unprocessed and is to the right of '#'
# We'll implement a finder that walks left until hitting '#' — if it hits '#' before finding unprocessed 0/1 -> y exhausted.

q_after_write_c0 0 -> 0 L q_find_next_y_c0
q_after_write_c0 1 -> 1 L q_find_next_y_c0

q_after_write_c1 0 -> 0 L q_find_next_y_c1
q_after_write_c1 1 -> 1 L q_find_next_y_c1

# q_find_next_y_c0: search left for unprocessed y bit (0/1) before hitting '#'
q_find_next_y_c0 0 -> 0 S q_process_y_c0
q_find_next_y_c0 1 -> 1 S q_process_y_c0
q_find_next_y_c0 X -> X L q_find_next_y_c0
q_find_next_y_c0 Y -> Y L q_find_next_y_c0
q_find_next_y_c0 # -> # S q_skip_hash_to_leftmost_unproc_x
q_find_next_y_c0 _ -> _ L q_find_next_y_c0
q_find_next_y_c0 M -> M L q_find_next_y_c0

q_find_next_y_c1 0 -> 0 S q_process_y_c1
q_find_next_y_c1 1 -> 1 S q_process_y_c1
q_find_next_y_c1 X -> X L q_find_next_y_c1
q_find_next_y_c1 Y -> Y L q_find_next_y_c1
q_find_next_y_c1 # -> # S q_skip_hash_to_leftmost_unproc_x
q_find_next_y_c1 _ -> _ L q_find_next_y_c1
q_find_next_y_c1 M -> M L q_find_next_y_c1

# q_skip_hash_to_leftmost_unproc_x: y exhausted; now process remaining x bits (to left of '#') with current carry
# We'll move left past '#' and then find rightmost unprocessed x bit (closest to '#') and process it similarly treating y=0
q_skip_hash_to_leftmost_unproc_x # -> # L q_find_unproc_x_c0   # choose appropriate carry variant externally
q_skip_hash_to_leftmost_unproc_x X -> X L q_skip_hash_to_leftmost_unproc_x
q_skip_hash_to_leftmost_unproc_x Y -> Y L q_skip_hash_to_leftmost_unproc_x
q_skip_hash_to_leftmost_unproc_x 0 -> 0 L q_skip_hash_to_leftmost_unproc_x
q_skip_hash_to_leftmost_unproc_x 1 -> 1 L q_skip_hash_to_leftmost_unproc_x
q_skip_hash_to_leftmost_unproc_x _ -> _ L q_skip_hash_to_leftmost_unproc_x
# For deterministic carry flow we need to remember carry; previous states q_after_write_c0/q_after_write_c1 route here differently.
# For simplicity, create two concrete skip states for carry 0/1:

# (carried from earlier) route q_after_write_c0 -> q_find_unproc_x_c0, q_after_write_c1 -> q_find_unproc_x_c1
q_after_write_c0 # -> # L q_find_unproc_x_c0
q_after_write_c1 # -> # L q_find_unproc_x_c1

# if the head is on non-#, we continue moving left until find '#'
q_find_unproc_x_c0 0 -> 0 L q_find_unproc_x_c0
q_find_unproc_x_c0 1 -> 1 L q_find_unproc_x_c0
q_find_unproc_x_c0 X -> X L q_find_unproc_x_c0
q_find_unproc_x_c0 Y -> Y L q_find_unproc_x_c0
q_find_unproc_x_c0 # -> # L q_locate_rightmost_unproc_x_c0

q_find_unproc_x_c1 0 -> 0 L q_find_unproc_x_c1
q_find_unproc_x_c1 1 -> 1 L q_find_unproc_x_c1
q_find_unproc_x_c1 X -> X L q_find_unproc_x_c1
q_find_unproc_x_c1 Y -> Y L q_find_unproc_x_c1
q_find_unproc_x_c1 # -> # L q_locate_rightmost_unproc_x_c1

# q_locate_rightmost_unproc_x_c0: from just left of '#', step right one and find the rightmost unprocessed x bit by scanning left from '#' (we are left of '#', so move right to the cell just left of '#')
q_locate_rightmost_unproc_x_c0 # -> # R q_seek_rightmost_unproc_x_from_hash_c0
q_locate_rightmost_unproc_x_c1 # -> # R q_seek_rightmost_unproc_x_from_hash_c1

# q_seek_rightmost_unproc_x_from_hash_c0: move left from right of '#' to find first unprocessed x bit (0/1) from right side
q_seek_rightmost_unproc_x_from_hash_c0 0 -> 0 S q_process_single_x_c0
q_seek_rightmost_unproc_x_from_hash_c0 1 -> 1 S q_process_single_x_c0
q_seek_rightmost_unproc_x_from_hash_c0 X -> X R q_no_unproc_x_left_c0
q_seek_rightmost_unproc_x_from_hash_c0 Y -> Y R q_no_unproc_x_left_c0
q_seek_rightmost_unproc_x_from_hash_c0 _ -> _ R q_no_unproc_x_left_c0

q_seek_rightmost_unproc_x_from_hash_c1 0 -> 0 S q_process_single_x_c1
q_seek_rightmost_unproc_x_from_hash_c1 1 -> 1 S q_process_single_x_c1
q_seek_rightmost_unproc_x_from_hash_c1 X -> X R q_no_unproc_x_left_c1
q_seek_rightmost_unproc_x_from_hash_c1 Y -> Y R q_no_unproc_x_left_c1
q_seek_rightmost_unproc_x_from_hash_c1 _ -> _ R q_no_unproc_x_left_c1

# q_process_single_x_c0: we are on an unprocessed x bit (0/1), mark it (X or Y), compute with y=0 and carry accordingly
q_process_single_x_c0 0 -> X R q_write0_next_c0_after_xonly   # 0 + 0 + carry0 = 0
q_process_single_x_c0 1 -> Y R q_write1_next_c0_after_xonly   # 1 + 0 + 0 = 1

q_process_single_x_c1 0 -> X R q_write1_next_c0_after_xonly   # 0 + 0 + 1 = 1 -> carry becomes 0
q_process_single_x_c1 1 -> Y R q_write0_next_c1_after_xonly   # 1 + 0 + 1 = 0 carry1

# q_no_unproc_x_left_* : no unprocessed x bits remain
q_no_unproc_x_left_c0 0 -> 0 R q_check_final_done_c0
q_no_unproc_x_left_c0 1 -> 1 R q_check_final_done_c0
q_no_unproc_x_left_c0 X -> X R q_check_final_done_c0
q_no_unproc_x_left_c0 Y -> Y R q_check_final_done_c0
q_no_unproc_x_left_c0 _ -> _ R q_check_final_done_c0

q_no_unproc_x_left_c1 0 -> 0 R q_check_final_done_c1
q_no_unproc_x_left_c1 1 -> 1 R q_check_final_done_c1
q_no_unproc_x_left_c1 X -> X R q_check_final_done_c1
q_no_unproc_x_left_c1 Y -> Y R q_check_final_done_c1
q_no_unproc_x_left_c1 _ -> _ R q_check_final_done_c1

# q_write*_after_xonly : similar to q_write_next states, find location to the right to put result: the rightmost y cell (or if none, create space)
q_write0_next_c0_after_xonly 0 -> 0 R q_write0_next_c0_after_xonly
q_write0_next_c0_after_xonly 1 -> 1 R q_write0_next_c0_after_xonly
q_write0_next_c0_after_xonly # -> # R q_write0_next_c0_after_xonly
q_write0_next_c0_after_xonly _ -> _ L q_put0_final_leftmost
q_put0_final_leftmost _ -> 0 R q_check_final_done_c0

q_write1_next_c0_after_xonly 0 -> 0 R q_write1_next_c0_after_xonly
q_write1_next_c0_after_xonly 1 -> 1 R q_write1_next_c0_after_xonly
q_write1_next_c0_after_xonly # -> # R q_write1_next_c0_after_xonly
q_write1_next_c0_after_xonly _ -> _ L q_put1_final_leftmost
q_put1_final_leftmost _ -> 1 R q_check_final_done_c0

# q_write0_next_c1_after_xonly and q_write1_next_c1_after_xonly analogous
q_write0_next_c1_after_xonly 0 -> 0 R q_write0_next_c1_after_xonly
q_write0_next_c1_after_xonly 1 -> 1 R q_write0_next_c1_after_xonly
q_write0_next_c1_after_xonly # -> # R q_write0_next_c1_after_xonly
q_write0_next_c1_after_xonly _ -> _ L q_put0_final_leftmost_c1
q_put0_final_leftmost_c1 _ -> 0 R q_check_final_done_c1

q_write1_next_c1_after_xonly 0 -> 0 R q_write1_next_c1_after_xonly
q_write1_next_c1_after_xonly 1 -> 1 R q_write1_next_c1_after_xonly
q_write1_next_c1_after_xonly # -> # R q_write1_next_c1_after_xonly
q_write1_next_c1_after_xonly _ -> _ L q_put1_final_leftmost_c1
q_put1_final_leftmost_c1 _ -> 1 R q_check_final_done_c1

# q_check_final_done_c0: if carry 0 and no unprocessed x left -> cleanup left side and accept
q_check_final_done_c0 0 -> 0 R q_check_final_done_c0
q_check_final_done_c0 1 -> 1 R q_check_final_done_c0
q_check_final_done_c0 X -> X R q_check_final_done_c0
q_check_final_done_c0 Y -> Y R q_check_final_done_c0
q_check_final_done_c0 # -> # R q_cleanup_left
q_check_final_done_c0 _ -> _ R q_cleanup_left

# q_check_final_done_c1: if carry 1 and no unprocessed x left -> must write final carry 1 to left of current MSB, then cleanup
q_check_final_done_c1 0 -> 0 R q_check_final_done_c1
q_check_final_done_c1 1 -> 1 R q_check_final_done_c1
q_check_final_done_c1 X -> X R q_check_final_done_c1
q_check_final_done_c1 Y -> Y R q_check_final_done_c1
q_check_final_done_c1 # -> # R q_write_final_carry
q_check_final_done_c1 _ -> _ R q_write_final_carry

# q_write_final_carry: move left until find first blank to left of result and write 1
q_write_final_carry 0 -> 0 L q_write_final_carry
q_write_final_carry 1 -> 1 L q_write_final_carry
q_write_final_carry X -> X L q_write_final_carry
q_write_final_carry Y -> Y L q_write_final_carry
q_write_final_carry # -> # L q_write_final_carry
q_write_final_carry _ -> 1 R q_cleanup_left

# q_cleanup_left: erase everything left of the first result digit (left of the leftmost result) and replace separator with blank, then accept
q_cleanup_left 0 -> _ R q_cleanup_left
q_cleanup_left 1 -> _ R q_cleanup_left
q_cleanup_left X -> _ R q_cleanup_left
q_cleanup_left Y -> _ R q_cleanup_left
q_cleanup_left # -> _ R q_cleanup_left
q_cleanup_left _ -> _ S q_done

# q_done is accepting state (already declared as accept)
# q_reject handles malformed inputs
q_reject 0 -> 0 S q_reject
q_reject 1 -> 1 S q_reject
q_reject _ -> _ S q_reject
