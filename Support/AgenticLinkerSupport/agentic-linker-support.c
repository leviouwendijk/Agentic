#include "AgenticLinkerSupport.h"

#include <stdint.h>

#if defined(__ELF__)
extern const unsigned char __start_agentic_catalog[] __attribute__((weak));
extern const unsigned char __stop_agentic_catalog[] __attribute__((weak));
#endif

const void *agentic_catalog_section_start(void) {
#if defined(__ELF__)
    if ((uintptr_t)__start_agentic_catalog == 0) {
        return 0;
    }

    return __start_agentic_catalog;
#else
    return 0;
#endif
}

const void *agentic_catalog_section_stop(void) {
#if defined(__ELF__)
    if ((uintptr_t)__stop_agentic_catalog == 0) {
        return 0;
    }

    return __stop_agentic_catalog;
#else
    return 0;
#endif
}
