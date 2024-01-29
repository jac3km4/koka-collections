#include <kklib.h>

static inline kk_vector_t kk_vector_updated(kk_vector_t vec, size_t index,
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
