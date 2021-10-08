#ifndef _ENDIAN_H
#define _ENDIAN_H

#include <freestanding/byteorder.h>
#include <stdint.h>

#define bswap16(x) __builtin_bswap16(x)
#define bswap32(x) __builtin_bswap32(x)
#define bswap64(x) __builtin_bswap64(x)

#if BYTE_ORDER == LITTLE_ENDIAN

#define htobe16(x) bswap16(x)
#define htobe32(x) bswap32(x)
#define htobe64(x) bswap64(x)
#define htole16(x) (uint16_t)(x)
#define htole32(x) (uint32_t)(x)
#define htole64(x) (uint64_t)(x)

#define be16toh(x) bswap16(x)
#define be32toh(x) bswap32(x)
#define be64toh(x) bswap64(x)
#define le16toh(x) (uint16_t)(x)
#define le32toh(x) (uint32_t)(x)
#define le64toh(x) (uint64_t)(x)

#else /* BYTE_ORDER != LITTLE_ENDIAN */

#define htobe16(x) (uint16_t)(x)
#define htobe32(x) (uint32_t)(x)
#define htobe64(x) (uint64_t)(x)
#define htole16(x) bswap16(x)
#define htole32(x) bswap32(x)
#define htole64(x) bswap64(x)

#define be16toh(x) (uint16_t)(x)
#define be32toh(x) (uint32_t)(x)
#define be64toh(x) (uint64_t)(x)
#define le16toh(x) bswap16(x)
#define le32toh(x) bswap32(x)
#define le64toh(x) bswap64(x)

#endif /* BYTE_ORDER == LITTLE_ENDIAN */

#endif /* _ENDIAN_H */
