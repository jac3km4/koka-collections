module hamt
import std/core/undiv
import std/num/int32

import utils

inline val default-cap = two32

// A persistent map implemented as a hash array mapped trie.
// Supports insertion and lookup in O(log32 n) time.
// See https://github.com/mkirchner/hamt for details.
pub value struct map<k, v>
  table : table<k, v>
  size : int

// Create an empty map.
pub fun map/empty(): map<k, v>
  Map(Table(new-vector(default-cap), zero32), 0)

// Create a map with a single key-value pair.
pub inline fun map/singleton(
  key : k,
  value : v,
  ?cmp: (k, k) -> order,
  ?hash: (k, int32) -> int32
): map<k, v>
  map/empty().insert(key, value)

// Lookup a value in the map.
pub inline fun map/get(
  ^this : map<k, v>,
  key : k,
  ?cmp: (k, k) -> order,
  ?hash: (k, int32) -> int32
): maybe<v>
  this.table.search(hash-state/new(key))

// Insert a value into the map.
pub fun map/insert(
  this : map<k, v>,
  key : k,
  value : v,
  ?cmp: (k, k) -> order,
  ?hash: (k, int32) -> int32
): map<k, v>
  val Map(table, size) = this
  val (table', added) = table.insert(hash-state/new(key), value)
  if added then
    Map(table', size + 1)
  else
    Map(table', size)

// Fold over the elements of the map.
pub inline fun map/foldl( this : map<k, v>, z : a, f : (a, k, v) -> e a ): e a
  Tab(this.table).foldl(z, f)

// Fold over the elements of the map.
pub inline fun map/foldr( this : map<k, v>, z : a, f : (k, v, a) -> e a ): e a
  Tab(this.table).foldr(z, f)

// Invoke a function for each element in the map.
pub inline fun map/foreach( ^this : map<k, v>, f : (k, v) -> e unit ): e unit
  Tab(this.table).foreach(f)

// Convert the map to a list of key-value pairs.
pub fun map/list( this : map<k, v> ): list<(k, v)>
  this.foldr(Nil) fn(k, v, acc) Cons((k, v), acc)

// Convert a list of key-value pairs to a map.
pub fun list/map( l : list<(k, v)>, ?cmp: (k, k) -> order, ?hash: (k, int32) -> int32 ): map<k, v>
  l.foldl(map/empty()) fn(acc, (k, v)) acc.insert(k, v)

// Get the number of elements in the map.
pub inline fun map/length( ^this : map<k, v> ): int
  this.size

struct table<k, v>
  nodes : vector<node<k, v>>
  index : int32

tail fun table/search(
  this : table<k, v>,
  state : hash-state<k>,
  ?cmp: (k, k) -> order,
  ?hash: (k, int32) -> int32
): maybe<v>
  val Table(nodes, index) = this
  val expected-index = state.get-index
  if index-contains(index, expected-index) then
    val pos = index-entry-pos(expected-index, index)
    match vector-at(nodes, pos)
      KeyVal(k, v) | cmp(k, state.key) == Eq -> Just(v)
      KeyVal(_, _) -> Nothing
      Tab(tab) -> tab.search(pretend-decreasing(state.next))
  else
    Nothing

fun table/insert(
  this : table<k, v>,
  state : hash-state<k>,
  value : v,
  ?cmp: (k, k) -> order,
  ?hash: (k, int32) -> int32
): (table<k, v>, bool)
  val Table(nodes, index) = this
  val expected-index = state.get-index
  if index-contains(index, expected-index) then
    val pos = index-entry-pos(expected-index, index)
    val (node, added) = match vector-at(nodes, pos)
      KeyVal(key', value') ->
        if cmp(key', state.key) == Eq then
          (KeyVal(key', value), False)
        else
          val existing-hash = hash(key', state.depth / 5.int32)
          val existing = HashState(key', existing-hash, state.depth, state.shift)
          val tab = table/new(existing, value', state, value)
          (Tab(tab), True)
      Tab(tab) ->
        val (tab', added) = tab.insert(pretend-decreasing(state.next), value)
        (Tab(tab'), added)
    (Table(nodes.update-vector(pos, node), index), added)
  else
    val new-index = index.or(one32.shl32(expected-index))
    val pos = index-entry-pos(expected-index, new-index)
    val vec = nodes.insert-vector(pos, KeyVal(state.key, value))
    (Table(vec, new-index), True)

fun table/new(
  existing: hash-state<k>,
  existing-value: v,
  new: hash-state<k>,
  new-value: v,
  ?hash: (k, int32) -> int32
): table<k, v>
  val existing' = existing.next
  val new' = new.next
  val existing-index = existing'.get-index
  val new-index = new'.get-index
  val node-index = one32.shl32(new-index)
  if existing-index == new-index then
    val tab = table/new(pretend-decreasing(existing'), existing-value, new', new-value)
    Table(new-vector(one32).update-vector(zero32, Tab(tab)), node-index)
  else
    val index' = node-index.or(one32.shl32(existing-index))
    val vec = new-vector(two32)
      .update-vector(index-entry-pos(existing-index, index'), KeyVal(existing.key, existing-value))
      .update-vector(index-entry-pos(new-index, index'), KeyVal(new.key, new-value))
    Table(vec, index')

type node<k, v>
  KeyVal ( key : k, value : v )
  Tab ( table : table<k, v> )

fun node/foldl( this : node<k, v>, z : a, f : (a, k, v) -> e a ): e a
  match this
    KeyVal(key, value) -> f(z, key, value)
    Tab(Table(nodes, index)) ->
      range/fold(0, index.index-size, z) fn(i, acc)
        pretend-decreasing(nodes.vector-at(i.int32)).foldl(acc, f)

fun node/foldr( this : node<k, v>, z : a, f : (k, v, a) -> e a ): e a
  match this
    KeyVal(key, value) -> f(key, value, z)
    Tab(Table(nodes, index)) ->
      val len = index.index-size
      range/fold(0, len, z) fn(i, acc)
        pretend-decreasing(nodes.vector-at((len - i - 1).int32)).foldr(acc, f)

fun node/foreach( ^this : node<k, v>, f : (k, v) -> e unit ): e unit
  match this
    KeyVal(key, value) -> f(key, value)
    Tab(tab) ->
      for(tab.index.index-size) fn(i)
        pretend-decreasing(tab.nodes.vector-at(i.int32)).foreach(f)

type hash-state<k>
  HashState
    key : k
    hash : int32
    depth : int32
    shift : int32

fun hash-state/new( key : k, ?hash: (k, int32) -> int32 ): hash-state<k>
  HashState(key, hash(key, zero32), zero32, zero32)

fun hash-state/next( this : hash-state<k>, ?hash: (k, int32) -> int32 ): hash-state<k>
  val HashState( key, hash', depth, shift ) = this
  if shift > 20.int32 then
    HashState(key, hash(key, depth + one32), depth + one32, zero32)
  else
    HashState(key, hash', depth + one32, shift + 5.int32)

fun hash-state/get-index( ^this : hash-state<k> ): int32
  this.hash.shr32(this.shift).and(0x1f.int32)

fip fun index-entry-pos( index : int32, bitmap : int32 ): int32
  bitmap.and(one32.shl32(index) - one32).popcount32

fip fun index-contains( index : int32, i : int32 ): bool
  index.and(one32.shl32(i)).bool

fip fun index-size( index : int32 ): int
  index.popcount
