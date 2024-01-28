import std/time/duration
import std/time/timer

import dlist
import pvec

// Slow list lookup by index for comparison
fun list/at( xs: list<a>, i: int ): exn a
  match xs
    Cons(x, xs) ->
      if i == 0 then
        x
      else
        xs.at(i - 1)

pub fun main()
  val (l-time, l) = elapsed
    reverse(range/fold(0, 10000000, Nil) fn(e, acc) Cons(e, acc))
  println("list cons + reverse ms: " ++ l-time.milli-seconds.show)

  val (d-time, _) = elapsed
    dlist/list(range/fold(0, 10000000, dlist/empty()) fn(e, acc) acc.snoc(e))
  println("dlist snoc ms: " ++ d-time.milli-seconds.show)

  val (v-time, v) = elapsed
    range/fold(0, 10000000, pvec/empty()) fn(e, acc) acc.snoc(e)
  println("pvec snoc ms: " ++ v-time.milli-seconds.show)

  val (ll-time, _) = elapsed
    for(0, 100000) fn(i)
      l.at(i)
      ()
  println("list lookup ms: " ++ ll-time.milli-seconds.show)

  val (vl-time, _) = elapsed
    for(0, 100000) fn(i)
      v.at(i)
      ()
  println("pvec lookup ms: " ++ vl-time.milli-seconds.show)
