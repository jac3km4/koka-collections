import std/time/duration
import std/time/timer
import std/num/int32

import dlist
import pvec
import hamt
import seq
import utils

// Slow list lookup by index for comparison.
fun list/at( xs: list<a>, i: int ): exn a
  match xs
    Cons(x, xs) ->
      if i == 0 then
        x
      else
        xs.at(i - 1)

fun viewr-sum-seq( seq: seq<int>, acc : int ) : div int
  match seq.viewr
    SnocR(xs, x) -> viewr-sum-seq(xs, acc + x)
    EmptyR -> acc

// Dummy hash function used for the map.
pub fun hash( x : int, seed : int32 ) : int32
  x.int32 * (2654435761.int32 + seed)

fun measured( label : string, f: () -> <ndet,console|e> a ): <ndet,console|e> a
  val (time, res) = elapsed { f() }
  println(label ++ " ms: " ++ time.milli-seconds.show)
  res

pub fun main()
  val l = measured("list cons x 10000000 + reverse")
    reverse(fold(10000000, Nil) fn(e, acc) Cons(e, acc))

  val _ = measured("dlist snoc x 10000000 + list")
    dlist/list(fold(10000000, dlist/empty()) fn(e, acc) acc.snoc(e))

  val s = measured("seq snoc x 10000000")
    fold(10000000, seq/empty()) fn(e, acc) acc.snoc(e)

  val v = measured("pvec snoc x 10000000")
    fold(10000000, pvec/empty()) fn(e, acc) acc.snoc(e)

  val m = measured("map insert x 10000000")
    fold(10000000, map/empty()) fn(e, acc) acc.insert(e, e)
  
  measured("map over a list of 10000000")
    l.map(fn(x) x + 1)

  measured("map over a seq of 10000000")
    s.map(fn(x) x + 1)

  measured("lookup in a list x 100000")
    for(0, 100000) fn(i)
      l.at(i)
      ()

  measured("lookup in a vec x 100000")
    for(0, 100000) fn(i)
      v.at(i)
      ()

  measured("lookup in a map x 100000")
    for(0, 100000) fn(i)
      m.get(i)
      ()

  measured("seq of 10000000 to list")
    s.list
  
  measured("pvec of 10000000 to list")
    v.list

  measured("map of 10000000 to list")
    m.list

  measured("viewr sum of a seq x 10000000")
    viewr-sum-seq(s, 0)

  measured("foldl sum of a seq x 10000000")
    s.foldl(0, fn(x, acc) x + acc)

  ()
