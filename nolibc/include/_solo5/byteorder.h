#ifndef __FREESTANDING_BYTEORDER_H
#define __FREESTANDING_BYTEORDER_H

#if !defined(__BYTE_ORDER__)
#error C compiler does not define __BYTE_ORDER__
#endif

#if defined(BYTE_ORDER) || defined(LITTLE_ENDIAN) || defined(BIG_ENDIAN)
#error BYTE_ORDER, LITTLE_ENDIAN or BIG_ENDIAN must not be defined here
#endif

#define BYTE_ORDER __BYTE_ORDER__
#define LITTLE_ENDIAN __ORDER_LITTLE_ENDIAN__
#define BIG_ENDIAN __ORDER_BIG_ENDIAN__

#endif /* __FREESTANDING_BYTEORDER_H */
