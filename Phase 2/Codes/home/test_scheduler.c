#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>

#define __NR_set_scheduler 260

int main(int argc, char *argv[]) {
    int mode;
    
    if (argc != 2) {
        printf("Usage: %s <mode>\n", argv[0]);
        printf("  0 = Default scheduler\n");
        printf("  1 = Lottery scheduler\n");
        return 1;
    }
    
    mode = atoi(argv[1]);
    
    /* Call system call */
    long result = syscall(__NR_set_scheduler, mode);
    
    if (result == 0) {
        printf("Successfully switched to %s scheduler\n",
               mode == 0 ? "DEFAULT" : "LOTTERY");
    } else {
        printf("Failed to switch scheduler\n");
        return 1;
    }
    
    return 0;
}