#!/bin/sh -eu

MIMALLOC_ALIB="/usr/lib/mimalloc-2.1/libmimalloc.a"
RAND="$(head -c 8 /dev/urandom | xxd -p)"

# Patch libc to use mimalloc
# shellcheck disable=SC2043
for libc_path in "/usr/lib/libc.a"; do
  if strings "$libc_path" | grep -q "mimalloc"; then
    echo "$(basename "$libc_path") is already patched with mimalloc."
    exit 0
  fi
  {
    echo "CREATE $RAND.a"
    echo "ADDLIB $libc_path"
    echo "DELETE aligned_alloc.lo calloc.lo donate.lo free.lo libc_calloc.lo lite_malloc.lo malloc.lo malloc_usable_size.lo memalign.lo posix_memalign.lo realloc.lo reallocarray.lo valloc.lo"
    echo "ADDLIB $MIMALLOC_ALIB"
    echo "SAVE"
  } | ar -M
  mv "$RAND.a" "$libc_path" || echo "ERROR: unable to patch libc" || exit 1
done

echo "SUCCESS: libc has been patched with mimalloc."
exit 0
