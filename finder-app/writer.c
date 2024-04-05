#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

void write_string_file(const char *writefile, const char *writestr) {
    // Open the file for writing
    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        // Log error message using syslog
        syslog(LOG_ERR, "Error opening file %s", writefile);
        perror("Error opening file");
        exit(1);
    }

    fprintf(file, "%s", writestr);
    fclose(file);
    syslog(LOG_DEBUG, "Writing %s to %s success", writestr, writefile);
}

int main(int argc, char *argv[]) {

    if (argc != 3) {
        fprintf(stderr, "Usage: %s <writefile> <writestr>\n", argv[0]);
        exit(1);
    }

    openlog(argv[0], LOG_PID | LOG_CONS, LOG_USER);

    const char *writefile = argv[1];
    const char *writestr = argv[2];
    write_string_file(writefile, writestr);

    closelog();

    return 0;
}