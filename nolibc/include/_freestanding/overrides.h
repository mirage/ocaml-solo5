#ifndef __FREESTANDING_OVERRIDES_H
#define __FREESTANDING_OVERRIDES_H

#undef __FreeBSD__
#undef __OpenBSD__
#undef __gnu_linux__
#undef __linux
#undef __linux__
#undef linux

#define __ocaml_freestanding__

#endif /* __FREESTANDING_OVERRIDES_H */
