module seq

// A persistent sequence data structure implemented as a 2-3 finger tree.
// Supports O(1) cons and snoc, and O(log min(i, n - i)) lookup and update.
// See https://www.staff.city.ac.uk/~ross/papers/FingerTree.html for details.
pub value struct seq<a>
  root : tree<elem<a>>

// Create an empty sequence.
pub inline fun seq/empty() : seq<a>
  Seq(Empty)

// Create a sequence with a single element.
pub inline fun seq/singleton( x : a ) : seq<a>
  Seq(Single(Elem(x)))

// Append an element to the sequence.
pub fun seq/snoc( this : seq<a>, x : a ) : seq<a>
  val Seq(root) = this
  Seq(root.snoc(Elem(x)))

// Prepend an element to the sequence.
pub fun seq/cons( x : a, this : seq<a> ) : seq<a>
  val Seq(root) = this
  Seq(Elem(x).cons(root))

// Lookup the element at the given index.
pub fun seq/at( ^this : seq<a>, i : int ) : maybe<a>
  this.root.at(i).map(fn((Elem(x), _)) x)

// Modify the element at the given index.
pub fun seq/modify( this : seq<a>, i : int, f : a -> <exn|e> a ) : <exn|e> seq<a>
  if i < 0 || i >= this.length then
    throw("index out of bounds")
  val Seq(root) = this
  Seq(root.modify(i, fn(Elem(x)) Elem(f(x))))

// Update the element at the given index.
pub inline fun seq/update( this : seq<a>, i : int, x : a ) : exn seq<a>
  this.modify(i, fn(_) x)

// Map a function over the sequence.
pub fun seq/map( this : seq<a>, ^f : a -> e b ) : e seq<b>
  val Seq(root) = this
  Seq(root.map(fn(Elem(x)) Elem(f(x))))

// Fold over the sequence from left to right.
pub fun seq/foldl( this : seq<a>, z : b, ^f : (b, a) -> e b ) : e b
  val Seq(root) = this
  root.foldl(z, fn(i, Elem(x)) f(i, x))

// Fold over the sequence from right to left.
pub fun seq/foldr( this : seq<a>, z : b, ^f : (a, b) -> e b ) : e b
  val Seq(root) = this
  root.foldr(z, fn(Elem(x), i) f(x, i))

// Convert the sequence to a list.
pub inline fun seq/list( this : seq<a> ): list<a>
  this.foldr([], Cons)

// Convert a list to a sequence.
pub inline fun list/seq( list : list<a> ) : seq<a>
  list.foldl(seq/empty(), seq/snoc)

// Analyze the sequence as a view from the left.
pub fun seq/viewl( this : seq<a> ) : viewl<a>
  val Seq(root) = this
  match root.viewl
    TreeEmptyL -> EmptyL
    TreeConsL(Elem(x), xs) -> ConsL(x, Seq(xs))

// Analyze the sequence as a view from the right.
pub fun seq/viewr( this : seq<a> ) : viewr<a>
  val Seq(root) = this
  match root.viewr
    TreeEmptyR -> EmptyR
    TreeSnocR(xs, Elem(x)) -> SnocR(Seq(xs), x)

// Get the length of the sequence.
pub inline fun seq/length( ^this : seq<a> ) : int
  this.root.size

type tree<a>
  Empty
  Single( value : a )
  Deep( size : int, pre : digit<a>, mid : tree<node<a>>, post : digit<a> )

fbip fun tree/size( ^this : tree<a> ) : int
  match this
    Empty -> 0
    Single(_) -> 1
    Deep(s, _, _, _) -> s

fun tree/cons( x : a, this : tree<a>, ?size: a -> int ) : tree<a>
  match this
    Empty -> Single(x)
    Single(y) -> Deep(2, One(x), Empty, One(y))
    Deep(s, Four(a, b, c, d), m, r) ->
      Deep(s + x.size, Two(x, a), Triple(b, c, d).cons(m), r)
    Deep(s, Three(a, b, c), m, r) ->
      Deep(s + x.size, Four(x, a, b, c), m, r)
    Deep(s, Two(a, b), m, r) ->
      Deep(s + x.size, Three(x, a, b), m, r)
    Deep(s, One(a), m, r) ->
      Deep(s + x.size, Two(x, a), m, r)

fun tree/snoc( this : tree<a>, x : a, ?size: a -> int ) : tree<a>
  match this
    Empty -> Single(x)
    Single(y) -> Deep(2, One(y), Empty, One(x))
    Deep(s, l, m, Four(a, b, c, d)) ->
      Deep(s + x.size, l, m.snoc(Triple(a, b, c)), Two(d, x))
    Deep(s, l, m, Three(a, b, c)) ->
      Deep(s + x.size, l, m, Four(a, b, c, x))
    Deep(s, l, m, Two(a, b)) ->
      Deep(s + x.size, l, m, Three(a, b, x))
    Deep(s, l, m, One(a)) ->
      Deep(s + x.size, l, m, Two(a, x))

fun tree/at( ^this : tree<a>, ^i : int, ?size: a -> int ) : maybe<(a, int)>
  match this
    Empty -> Nothing
    Single(x) -> Just((x, i))
    Deep(_, l, m, r) ->
      val ls = l.size
      if i < ls then
        Just(l.at(i))
      else if i < ls + m.size then
        match m.at(i - ls)
          Just((x, i')) -> Just(x.at(i'))
          Nothing -> Nothing
      else
        Just(r.at(i - ls - m.size))

fun tree/modify( this : tree<a>, i : int, f : a -> e a, ?size: a -> int ) : e tree<a>
  match this
    Empty -> Empty
    Single(x) -> Single(f(x))
    Deep(s, l, m, r) ->
      val ls = l.size
      if i < ls then
        Deep(s, l.modify(i, f), m, r)
      else if i < ls + m.size then
        Deep(s, l, m.modify(i - ls, fn(x) x.modify(i, f)), r)
      else
        Deep(s, l, m, r.modify(i - ls - m.size, f))

fun tree/map( this : tree<a>, ^f : a -> e b ) : e tree<b>
  match this
    Empty -> Empty
    Single(x) -> Single(f(x))
    Deep(s, l, m, r) ->
      Deep(s, l.map(f), m.map(fn(x) x.map(f)), r.map(f))

fun tree/foldl( this : tree<a>, i : b, ^f : (b, a) -> e b ) : e b
  match this
    Empty -> i
    Single(x) -> f(i, x)
    Deep(_, l, m, r) ->
      val i' = l.foldl(i, f)
      val i'' = m.foldl(i', fn(i''', x) x.foldl(i''', f))
      r.foldl(i'', f)

fun tree/foldr( this : tree<a>, i : b, ^f : (a, b) -> e b ) : e b
  match this
    Empty -> i
    Single(x) -> f(x, i)
    Deep(_, l, m, r) ->
      val i' = r.foldr(i, f)
      val i'' = m.foldr(i', fn(x, i''') x.foldr(i''', f))
      l.foldr(i'', f)

fun tree/viewl( this : tree<a>, ?size: a -> int ) : tree-viewl<a>
  match this
    Empty -> TreeEmptyL
    Single(x) -> TreeConsL(x, Empty)
    Deep(s, One(a), m, r) ->
      val s' = s - a.size
      val m' = match m.viewl
        TreeEmptyL -> r.to-sized-tree(s')
        TreeConsL(x, xs) -> Deep(s', x.to-digit, xs, r)
      TreeConsL(a, m')
    Deep(s, Two(a, b), m, r) ->
      TreeConsL(a, Deep(s - a.size, One(b), m, r))
    Deep(s, Three(a, b, c), m, r) ->
      TreeConsL(a, Deep(s - a.size, Two(b, c), m, r))
    Deep(s, Four(a, b, c, d), m, r) ->
      TreeConsL(a, Deep(s - a.size, Three(b, c, d), m, r))

fun tree/viewr( this : tree<a>, ?size: a -> int ) : tree-viewr<a>
  match this
    Empty -> TreeEmptyR
    Single(x) -> TreeSnocR(Empty, x)
    Deep(s, l, m, One(a)) ->
      val s' = s - a.size
      val m' = match m.viewr
        TreeEmptyR -> l.to-sized-tree(s')
        TreeSnocR(xs, x) -> Deep(s', l, xs, x.to-digit)
      TreeSnocR(m', a)
    Deep(s, l, m, Two(a, b)) ->
      TreeSnocR(Deep(s - b.size, l, m, One(a)), b)
    Deep(s, l, m, Three(a, b, c)) ->
      TreeSnocR(Deep(s - c.size, l, m, Two(a, b)), c)
    Deep(s, l, m, Four(a, b, c, d)) ->
      TreeSnocR(Deep(s - d.size, l, m, Three(a, b, c)), d)

type node<a>
  Tuple( fst : a, snd : a )
  Triple( fst : a, snd : a, thd : a )

fun node/size( this : node<a>, ?size: a -> int ) : int
  match this
    Tuple(x, y) -> x.size + y.size
    Triple(x, y, z) -> x.size + y.size + z.size

fun node/at( ^this : node<a>, ^i : int, ?size: a -> int ) : (a, int)
  match this
    Tuple(x, y) ->
      val xs = x.size
      if i < xs then
        (x, i)
      else
        (y, i - xs)
    Triple(x, y, z) ->
      val xs = x.size
      val ys = y.size
      if i < xs then
        (x, i)
      else if i < xs + ys then
        (y, i - xs)
      else
        (z, i - xs - ys)

fun node/modify( this : node<a>, i : int, f : a -> e a, ?size: a -> int ) : e node<a>
  match this
    Tuple(x, y) ->
      val xs = x.size
      if i < xs then
        Tuple(f(x), y)
      else
        Tuple(x, f(y))
    Triple(x, y, z) ->
      val xs = x.size
      val ys = y.size
      if i < xs then
        Triple(f(x), y, z)
      else if i < xs + ys then
        Triple(x, f(y), z)
      else
        Triple(x, y, f(z))

fip fun node/map( this : node<a>, ^f : a -> e b ) : e node<b>
  match this
    Tuple(x, y) -> Tuple(f(x), f(y))
    Triple(x, y, z) -> Triple(f(x), f(y), f(z))

fbip fun node/foldl( this : node<a>, i : b, ^f : (b, a) -> e b ) : e b
  match this
    Tuple(x, y) -> f(f(i, x), y)
    Triple(x, y, z) -> f(f(f(i, x), y), z)

fbip fun node/foldr( this : node<a>, i : b, ^f : (a, b) -> e b ) : e b
  match this
    Tuple(x, y) -> f(x, f(y, i))
    Triple(x, y, z) -> f(x, f(y, f(z, i)))

fip fun node/to-digit( this : node<a> ) : digit<a>
  match this
    Tuple(x, y) -> Two(x, y)
    Triple(x, y, z) -> Three(x, y, z)

type digit<a>
  One( fst : a )
  Two( fst : a, snd : a )
  Three( fst : a, snd : a, thd : a )
  Four( fst : a, snd : a, thd : a, fth : a )

fun digit/size( this : digit<a>, ?size: a -> int ) : int
  match this
    One(x) -> x.size
    Two(x, y) -> x.size + y.size
    Three(x, y, z) -> x.size + y.size + z.size
    Four(x, y, z, w) -> x.size + y.size + z.size + w.size

fun digit/at( ^this : digit<a>, ^i : int, ?size: a -> int ) : (a, int)
  match this
    One(x) -> (x, i)
    Two(x, y) ->
      val xs = x.size
      if i < xs then
        (x, i)
      else
        (y, i - xs)
    Three(x, y, z) ->
      val xs = x.size
      val ys = y.size
      if i < xs then
        (x, i)
      else if i < xs + ys then
        (y, i - xs)
      else
        (z, i - xs - ys)
    Four(x, y, z, w) ->
      val xs = x.size
      val ys = y.size
      val zs = z.size
      if i < xs then
        (x, i)
      else if i < xs + ys then
        (y, i - xs)
      else if i < xs + ys + zs then
        (z, i - xs - ys)
      else
        (w, i - xs - ys - zs)

fun digit/modify( this : digit<a>, i : int, f : a -> e a, ?size: a -> int ) : e digit<a>
  match this
    One(x) -> One(f(x))
    Two(x, y) ->
      val xs = x.size
      if i < xs then
        Two(f(x), y)
      else
        Two(x, f(y))
    Three(x, y, z) ->
      val xs = x.size
      val ys = y.size
      if i < xs then
        Three(f(x), y, z)
      else if i < xs + ys then
        Three(x, f(y), z)
      else
        Three(x, y, f(z))
    Four(x, y, z, w) ->
      val xs = x.size
      val ys = y.size
      val zs = z.size
      if i < xs then
        Four(f(x), y, z, w)
      else if i < xs + ys then
        Four(x, f(y), z, w)
      else if i < xs + ys + zs then
        Four(x, y, f(z), w)
      else
        Four(x, y, z, f(w))

fip fun digit/map( this : digit<a>, ^f : a -> e b ) : e digit<b>
  match this
    One(x) -> One(f(x))
    Two(x, y) -> Two(f(x), f(y))
    Three(x, y, z) -> Three(f(x), f(y), f(z))
    Four(x, y, z, w) -> Four(f(x), f(y), f(z), f(w))

fbip fun digit/foldl( this : digit<a>, i : b, ^f : (b, a) -> e b ) : e b
  match this
    One(x) -> f(i, x)
    Two(x, y) -> f(f(i, x), y)
    Three(x, y, z) -> f(f(f(i, x), y), z)
    Four(x, y, z, w) -> f(f(f(f(i, x), y), z), w)

fbip fun digit/foldr( this : digit<a>, i : b, ^f : (a, b) -> e b ) : e b
  match this
    One(x) -> f(x, i)
    Two(x, y) -> f(x, f(y, i))
    Three(x, y, z) -> f(x, f(y, f(z, i)))
    Four(x, y, z, w) -> f(x, f(y, f(z, f(w, i))))

fbip(3) fun digit/to-sized-tree( this : digit<a>, n : int ) : tree<a>
  match this
    One(x) -> Single(x)
    Two(x, y) -> Deep(n, One(x), Empty, One(y))
    Three(x, y, z) -> Deep(n, Two(x, y), Empty, One(z))
    Four(x, y, z, w) -> Deep(n, Two(x, y), Empty, Two(z, w))

value type elem<a>
  Elem( value : a )

inline fbip fun elem/size( this : elem<a> ) : int
  1

// A view of the left end of a sequence.
pub value type viewl<a>
  EmptyL
  ConsL( head : a, tail : seq<a> )

// A view of the right end of a sequence.
pub value type viewr<a>
  EmptyR
  SnocR( init : seq<a>, last : a )

value type tree-viewl<a>
  TreeEmptyL
  TreeConsL( head : a, tail : tree<a> )

value type tree-viewr<a>
  TreeEmptyR
  TreeSnocR( init : tree<a>, last : a )
