#include "test_shared.h"

#include <stdio.h>
#include <string.h>

int test_shared_version() {
    return 102;
}

int test_shared_min(int a, int b) {
    printf("test_shared_min : a=%d, b=%d\n", a, b);
    if (a <= b) {
        return a;
    } else {
        return b;
    }
}