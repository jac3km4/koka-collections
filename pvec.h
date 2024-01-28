#include <kklib.h>

static inline kk_vector_t kk_vector_updated(kk_vector_t vec, int32_t index,
                                            kk_box_t elem, kk_context_t *ctx) {

  kk_assert(index >= 0 && index < kk_vector_len(vec, ctx));

  kk_vector_t copy = kk_vector_copy(vec, ctx);
  kk_box_t *buf = kk_vector_buf_borrow(copy, NULL, ctx);
  kk_box_drop(buf[index], ctx);
  buf[index] = elem;
  return copy;
}
