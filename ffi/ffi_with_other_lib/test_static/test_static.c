#include "test_static.h"

#include <stdio.h>
#include <string.h>

int test_static_version() {
    return 101;
}

int test_static_max(int a, int b) {
    printf("test_static_max : a=%d, b=%d\n", a, b);
    if (a >= b) {
        return a;
    } else {
        return b;
    }
}