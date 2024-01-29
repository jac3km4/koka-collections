import std/num/int32
import std/core/undiv

inline val zero32 = 0.int32
inline val one32 = 1.int32
inline val int32-bits = 32.int32

inline val bits = 5.int32
inline val width = one32.shl(bits.int)
inline val bit-mask = width - one32

// A persistent vector backed by a bit-partitioned trie based on Clojure's vec.
// Supports O(log32(n)) lookup, update, and append.
// See https://clojure.org/reference/data_structures#Vectors.
pub value struct pvec<a>
  root: ptrie<a>
  len: int32

// Create a new empty vector.
pub fun pvec/empty(): pvec<a>
  Pvec(Node(new-vector(2.ssize_t), 0), zero32)

// Lookup the value at the given index.
pub inline fun pvec/at( ^this : pvec<a>, index : int ): exn maybe<a>
  this.root.lookup(index.int32, this.depth)

// Update the value at the given index.
pub fun pvec/update( this : pvec<a>, index : int, value : a ): exn pvec<a>
  val len = this.len + (index.int32 >= this.len).int32
  Pvec(this.root.update(index.int32, value, this.depth), len)

// Append a value to the end of the vector.
pub fun pvec/snoc( this : pvec<a>, value : a ): exn pvec<a>
  val len = this.len
  if len == this.capacity then
    Pvec(this.root.singleton-node, len + one32).update(len.int, value)
  else
    this.update(len.int, value)

// Invoke the given function for each element in the vector.
pub fun pvec/foreach( ^this : pvec<a>, f : (a) -> <exn|e> () ): <exn|e> ()
  for(this.len.int) fn(i)
    f(unjust(this.at(i)))

// Return the length of the vector.
pub fun pvec/length( ^this : pvec<a> ): int
  this.len.int

// Convert the vector to a list.
pub fun pvec/list( ^this : pvec<a> ): exn list<a>
  range/fold(0, this.length, Nil) fn(i, acc)
    Cons(unjust(this.at(this.length - i - 1)), acc)

inline fun pvec/capacity( ^this : pvec<a> ): int32
  one32.shl32(bits * (this.depth + one32))

fun pvec/depth( ^this : pvec<a> ): int32
  if this.len > zero32 then
    val b = int32-bits - (this.len - one32).clz.int32
    b / bits + (b % bits > zero32).int32 - one32
  else zero32

type ptrie<a>
  Node ( children : vector<ptrie<a>>, size : int )
  Leaf ( values : vector<a>, size : int )

fun ptrie/singleton-node( value : ptrie<a> ): ptrie<a>
  Node(new-vector(2.ssize_t).updated-vector(0.ssize_t, value), 1)

fun ptrie/lookup( this : ptrie<a>, index : int32, depth: int32 ): exn maybe<a>
  val next = index.child-index(depth).int
  match this
    Node( children, size ) | next < size ->
      children[next].lookup(index, pretend-decreasing(depth - one32))
    Leaf( values, size ) | next < size ->
      Just(values[next])
    _ -> Nothing

fun ptrie/update( this : ptrie<a>, index : int32, value : a, depth : int32 ) : exn ptrie<a>
  val next = index.child-index(depth).int
  match this
    Node( children, size ) ->
      val child =
        if next >= size then ptrie/new-child(depth)
        else children[next]
      val new-child = child.update(index, value, pretend-decreasing(depth - one32))
      Node(children.updated-vector(next.ssize_t, new-child), ptrie/get-size(next, size))
    Leaf( values, size ) ->
      Leaf(values.updated-vector(next.ssize_t, value), ptrie/get-size(next, size))

fun ptrie/child-index( index : int32, depth : int32 ): int32
  index.shr32(depth * bits).and(bit-mask)

fun ptrie/new-child( depth : int32 ): ptrie<a>
  if depth > one32 then
    Node(new-vector(2.ssize_t), 0)
  else
    Leaf(new-vector(2.ssize_t), 0)

fun ptrie/get-size( child-index : int, size : int ): int
  if child-index >= size
  then child-index + 1
  else size

extern import
  c file "pvec.h"

inline extern shl32( x : int32, y : int32 ): int32
  c inline "kk_shl32(#1, #2)"

inline extern shr32( x : int32, y : int32 ): int32
  c inline "kk_shr32(#1, #2)"

inline extern new-vector( n : ssize_t ): vector<a>
  c inline "kk_vector_alloc(#1, kk_box_null(), kk_context())"

noinline fip extern updated-vector( v : vector<a>, i : ssize_t, x : a ): vector<a>
  c inline "kk_vector_updated(#1, #2, #3, kk_context())"
