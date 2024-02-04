module utils
import std/num/int32

pub inline val zero32 = 0.int32
pub inline val one32 = 1.int32
pub inline val two32 = 2.int32

extern import
  c file "utils.h"

pub inline fip extern shl32( x : int32, y : int32 ): int32
  c inline "kk_shl32(#1, #2)"

pub inline fip extern shr32( x : int32, y : int32 ): int32
  c inline "kk_shr32(#1, #2)"

pub inline fip extern popcount32( i : int32 ) : int32
  c inline "kk_bits_popcount32(#1)"

pub inline fip extern new-vector( n : int32 ): vector<a>
  c inline "kk_vector_alloc(#1, kk_box_null(), kk_context())"

pub inline fip extern vector-at( ^v : vector<a>, i : int32 ): a
  c inline "kk_vector_at_borrow(#1, #2, kk_context())"

pub noinline fip extern update-vector( v : vector<a>, i : int32, x : a ): vector<a>
  c inline "vector_update(#1, #2, #3, kk_context())"

pub noinline fip extern insert-vector( v : vector<a>, i : int32, x : a ): vector<a>
  c inline "vector_insert(#1, #2, #3, kk_context())"
