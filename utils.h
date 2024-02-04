#include <kklib.h>

static inline int32_t murmur_32_scramble(int32_t k) {
  k *= 0xcc9e2d51;
  k = (k << 15) | (k >> 17);
  k *= 0x1b873593;
  return k;
}

static inline int32_t murmur3_32(const char *key, size_t len, int32_t seed) {
  int32_t h = seed;
  int32_t k;
  /* Read in groups of 4. */
  for (size_t i = len >> 2; i; i--) {
    memcpy(&k, key, sizeof(int32_t));
    key += sizeof(int32_t);
    h ^= murmur_32_scramble(k);
    h = (h << 13) | (h >> 19);
    h = h * 5 + 0xe6546b64;
  }
  /* Read the rest. */
  k = 0;
  for (size_t i = len & 3; i; i--) {
    k <<= 8;
    k |= key[i - 1];
  }
  h ^= murmur_32_scramble(k);
  /* Finalize. */
  h ^= len;
  h ^= h >> 16;
  h *= 0x85ebca6b;
  h ^= h >> 13;
  h *= 0xc2b2ae35;
  h ^= h >> 16;
  return h;
}

static inline kk_vector_t vector_insert(kk_vector_t vec, size_t index,
                                        kk_box_t elem, kk_context_t *ctx) {
  size_t old_len = kk_vector_len_borrow(vec, ctx);
  assert(index >= 0 && index <= old_len);
  size_t new_len = old_len + 1;

  kk_vector_t copy = kk_vector_alloc_uninit(new_len, NULL, ctx);
  kk_box_t *old_buf = kk_vector_buf_borrow(vec, NULL, ctx);
  kk_box_t *new_buf = kk_vector_buf_borrow(copy, NULL, ctx);

  for (size_t i = 0; i < new_len; i++) {
    if (i == index) {
      new_buf[i] = elem;
    } else if (i < index) {
      new_buf[i] = kk_box_dup(old_buf[i], ctx);
    } else {
      new_buf[i] = kk_box_dup(old_buf[i - 1], ctx);
    }
  }

  kk_vector_drop(vec, ctx);
  return copy;
}

static inline kk_vector_t vector_update(kk_vector_t vec, size_t index,
                                        kk_box_t elem, kk_context_t *ctx) {

  size_t old_len = kk_vector_len_borrow(vec, ctx);
  assert(index >= 0 && index <= old_len);

  if (index < old_len && kk_datatype_is_unique(vec, ctx)) {
    // we can modify the trie in place when it's not shared
    kk_box_t *buf = kk_vector_buf_borrow(vec, NULL, ctx);
    kk_box_drop(buf[index], ctx);
    buf[index] = elem;
    return vec;
  }

  size_t new_len = old_len;
  if (index == old_len) {
    new_len *= 2;
  }

  kk_vector_t copy = kk_vector_alloc_uninit(new_len, NULL, ctx);
  kk_box_t *old_buf = kk_vector_buf_borrow(vec, NULL, ctx);
  kk_box_t *new_buf = kk_vector_buf_borrow(copy, NULL, ctx);

  for (size_t i = 0; i < new_len; i++) {
    if (i == index) {
      new_buf[i] = elem;
    } else if (i < old_len) {
      new_buf[i] = kk_box_dup(old_buf[i], ctx);
    } else {
      new_buf[i] = kk_box_null();
    }
  }

  kk_vector_drop(vec, ctx);
  return copy;
}
