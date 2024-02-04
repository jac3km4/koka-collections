# koka-collections
Small koka collections library.

Currently consists of:
- [Sequence](/seq.kk)
  - implemented as a [2-3 finger tree](https://www.staff.city.ac.uk/~ross/papers/FingerTree.html)
  - O(1) cons and snoc
  - O(log min(i, n - i)) lookup and update
- [Persistent Vector](/pvec.kk)
  - implemented as a [bit-partitioned trie](https://github.com/clojure/clojure/blob/clojure-1.11.1/src/jvm/clojure/lang/PersistentVector.java)
  - O(log32 n) lookup, update, and snoc
- [Difference List](/dlist.kk)
  - implemented as a standard [difference list](https://wiki.haskell.org/Difference_list)
  - O(1) append and snoc
- [Immutable Map](/hamt.kk)
  - implemented as a [hash array mapped trie](https://github.com/mkirchner/hamt)
  - O(log32 n) lookup and insert
