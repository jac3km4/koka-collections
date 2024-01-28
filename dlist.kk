
// A difference list data structure based on Haskell's Data.DList.
// Supports O(1) append and snoc operations.
// See https://hackage.haskell.org/package/dlist-1.0/docs/Data-DList.html
pub value struct dlist<a>
  f: list<a> -> list<a>

// Create an empty difference list.
pub inline fun dlist/empty(): dlist<a>
  Dlist(id)

// Create a difference list from a single element.
pub fun dlist/singleton( a: a ): dlist<a>
  Dlist(fn(xs) Cons(a, xs))

// Append an element to a difference list.
pub fun dlist/snoc( l: dlist<a>, a: a ): dlist<a>
  l.append(a.singleton)

// Concatenate two difference lists.
pub fun dlist/append( l1: dlist<a>, l2: dlist<a> ): dlist<a>
  Dlist(l1.f.o(l2.f))

// Convert a difference list to a list.
pub inline fun dlist/list( l: dlist<a> ): list<a>
  l.f.apply(Nil)

// Convert a list to a difference list.
pub inline fun list/dlist( l: list<a> ): dlist<a>
  Dlist(fn(xs) xs ++ l)
