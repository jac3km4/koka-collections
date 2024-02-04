import std/time/duration
import std/time/timer

import dlist
import pvec
import hamt
import seq
import utils

// Slow list lookup by index for comparison
fun list/at( xs: list<a>, i: int ): exn a
  match xs
    Cons(x, xs) ->
      if i == 0 then
        x
      else
        xs.at(i - 1)

// Hash used for the map
pub fun hash( x : string, seed : int32 ) : int32
  murmur3-hash(x, seed)

fun measured( label : string, f: () -> <ndet,console|e> a ): <ndet,console|e> a
  val (time, res) = elapsed { f() }
  println(label ++ " ms: " ++ time.milli-seconds.show)
  res

pub fun main()
  val l = measured("list cons x 10000000 + reverse")
    reverse(range/fold(0, 10000000, Nil) fn(e, acc) Cons(e, acc))

  val _ = measured("dlist snoc x 10000000 + list")
    dlist/list(range/fold(0, 10000000, dlist/empty()) fn(e, acc) acc.snoc(e))

  val s = measured("seq snoc x 10000000")
    range/fold(0, 10000000, seq/empty()) fn(e, acc) acc.snoc(e)

  val v = measured("pvec snoc x 10000000")
    range/fold(0, 10000000, pvec/empty()) fn(e, acc) acc.snoc(e)

  val m = measured("map insert x 10000000")
    range/fold(0, 10000000, map/empty()) fn(e, acc) acc.insert(e.show, e)

  measured("map over a list of 10000000")
    l.map(fn(x) x + 1)

  measured("map over a seq of 10000000")
    s.map(fn(x) x + 1)

  measured("lookup in a list x 10000")
    for(0, 10000) fn(i)
      l.at(i)
      ()

  measured("lookup in a vec x 10000")
    for(0, 10000) fn(i)
      v.at(i)
      ()

  measured("lookup in a seq x 10000")
    for(0, 10000) fn(i)
      s.at(i)
      ()

  ()
