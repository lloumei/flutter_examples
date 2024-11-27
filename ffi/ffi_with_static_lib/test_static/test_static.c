#include "test_static.h"

#include <stdio.h>
#include <string.h>

int test_static_version() {
    return 1;
}

size_t test_static_hello(const char *msg) {
    printf("test_static_hello : msg=%s\n", msg);
    return strlen(msg);
}