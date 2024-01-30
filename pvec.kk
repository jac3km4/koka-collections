import std/num/int32
import std/core/undiv

inline val zero32 = 0.int32
inline val one32 = 1.int32
inline val int32-bits = 32.int32

inline val bits = 5.int32
inline val width = one32.shl(bits.int)
inline val bit-mask = width - one32
inline val default-cap = 2.int32

// A persistent vector backed by a bit-partitioned trie based on Clojure's vec.
// Supports O(log32(n)) lookup, update, and append.
// See https://clojure.org/reference/data_structures#Vectors.
pub value struct pvec<a>
  root: ptrie<a>
  len: int32

// Create a new empty vector.
pub fun pvec/empty(): pvec<a>
  Pvec(Node(new-vector(default-cap), zero32), zero32)

// Lookup the value at the given index.
pub inline fun pvec/at( ^this : pvec<a>, index : int ): maybe<a>
  this.root.lookup(index.int32, depth-by-len(this.len))

// Update the value at the given index.
pub fbip(n) fun pvec/update( this : pvec<a>, index : int, value : a ): pvec<a>
  val Pvec(root, len) = this
  val new-len = len + (index.int32 >= len).int32
  Pvec(root.update(index.int32, value, depth-by-len(len)), new-len)

// Append a value to the end of the vector.
pub fbip(n) fun pvec/snoc( this : pvec<a>, value : a ): pvec<a>
  val Pvec(root, len) = this
  if len == capacity-by-len(len) then
    Pvec(root.singleton-node, len + one32).update(len.int, value)
  else
    Pvec(root.update(len, value, depth-by-len(len)), len + one32)

// Invoke the given function for each element in the vector.
pub fun pvec/foreach( ^this : pvec<a>, f : (a) -> e () ): e ()
  for(this.len.int) fn(i)
    match this.at(i)
      Just(x) -> f(x)
      Nothing -> ()

// Return the length of the vector.
pub fun pvec/length( ^this : pvec<a> ): int
  this.len.int

// Convert the vector to a list.
pub fun pvec/list( ^this : pvec<a> ): list<a>
  range/fold(0, this.length, Nil) fn(i, acc)
    match this.at(this.length - i - 1)
      Just(x) -> Cons(x, acc)
      Nothing -> acc

type ptrie<a>
  Node ( children : vector<ptrie<a>>, size : int32 )
  Leaf ( values : vector<a>, size : int32 )

fip(1) fun ptrie/singleton-node( value : ptrie<a> ): ptrie<a>
  Node(new-vector(default-cap).updated-vector(zero32, value), one32)

fbip fun ptrie/lookup( this : ptrie<a>, index : int32, depth: int32 ): maybe<a>
  val next = index-by-depth(index, depth)
  match this
    Node( children, size ) | next < size ->
      vector-at(children, next).lookup(index, pretend-decreasing(depth - one32))
    Leaf( values, size ) | next < size ->
      Just(vector-at(values, next))
    _ -> Nothing

fbip(n) fun ptrie/update( this : ptrie<a>, index : int32, value : a, depth : int32 ) : ptrie<a>
  val next = index-by-depth(index, depth)
  match this
    Node( children, size ) ->
      val child =
        if next >= size then new-child-trie(depth)
        else vector-at(children, next)
      val new-child = child.update(index, value, pretend-decreasing(depth - one32))
      Node(children.updated-vector(next, new-child), updated-trie-size(next, size))
    Leaf( values, size ) ->
      Leaf(values.updated-vector(next, value), updated-trie-size(next, size))

inline fip fun capacity-by-len( len : int32 ): int32
  one32.shl32(bits * (depth-by-len(len) + one32))

fip fun depth-by-len( len : int32 ): int32
  if len > zero32 then
    val b = int32-bits - (len - one32).clz.int32
    b / bits + (b % bits > zero32).int32 - one32
  else zero32

fip fun index-by-depth( index : int32, depth : int32 ): int32
  index.shr32(depth * bits).and(bit-mask)

fip fun updated-trie-size( child-index : int32, size : int32 ): int32
  if child-index >= size
  then child-index + one32
  else size

fip(1) fun new-child-trie( depth : int32 ): ptrie<a>
  if depth > one32 then
    Node(new-vector(default-cap), zero32)
  else
    Leaf(new-vector(default-cap), zero32)

extern import
  c file "pvec.h"

inline fip extern shl32( x : int32, y : int32 ): int32
  c inline "kk_shl32(#1, #2)"

inline fip extern shr32( x : int32, y : int32 ): int32
  c inline "kk_shr32(#1, #2)"

inline fip extern new-vector( n : int32 ): vector<a>
  c inline "kk_vector_alloc(#1, kk_box_null(), kk_context())"

inline fip extern vector-at( ^v : vector<a>, i : int32 ): a
  c inline "kk_vector_at_borrow(#1, #2, kk_context())"

noinline fip extern updated-vector( v : vector<a>, i : int32, x : a ): vector<a>
  c inline "kk_vector_updated(#1, #2, #3, kk_context())"
