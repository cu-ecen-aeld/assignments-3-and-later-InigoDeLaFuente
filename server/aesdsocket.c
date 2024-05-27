#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include <arpa/inet.h>

static const int PORT = 9000;
static const int BUFFER_SIZE = 1024;
static const char* FILE_PATH = "/var/tmp/aesdsocketdata";

int server_fd;

// Signal handler for SIGINT and SIGTERM
void sig_handler(int signum) {
    if (signum == SIGINT || signum == SIGTERM) {
        // Log message
        syslog(LOG_INFO, "Caught signal, exiting");
        // Close server socket
        close(server_fd);
        // Delete file
        remove(FILE_PATH);
        // Log message
        syslog(LOG_INFO, "Closed server socket and deleted file %s", FILE_PATH);
        // Exit program
        exit(EXIT_SUCCESS);
    }
}

int main(int argc, char *argv[]) {
    int new_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE];
    FILE *file;

    int daemon_mode = 0;
    int option;
    while ((option = getopt(argc, argv, "d")) != -1) {
        switch (option) {
            case 'd':
                daemon_mode = 1;
                break;
            default:
                fprintf(stderr, "Usage: %s [-d]\n", argv[0]);
                exit(EXIT_FAILURE);
        }
    }

    // Register signal handler for SIGINT and SIGTERM
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);

    // Create socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        return -1;
    }

    // Set socket options
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        return -1;
    }

    // Bind socket to port
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        return -1;
    }

    // Listen for connections
    if (listen(server_fd, 3) < 0) {
        perror("listen failed");
        return -1;
    }

    if (daemon_mode) {
        pid_t pid = fork();
        if (pid < 0) {
            syslog(LOG_ERR, "Failed to fork");
            closelog();
            exit(EXIT_FAILURE);
        } else if (pid > 0) {
            // Parent process
            exit(EXIT_SUCCESS);
        }
        // Child process continues
        setsid();
    }

    // Accept incoming connections forever
    while (1) {
        // Accept incoming connection
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            perror("accept failed");
            return -1;
        }

        // Log accepted connection
        syslog(LOG_INFO, "Accepted connection from %s", inet_ntoa(address.sin_addr));

        // Open file for appending data
        file = fopen(FILE_PATH, "a");
        if (file == NULL) {
            perror("fopen failed");
            return -1;
        }
        
        ssize_t bytes_received;
        while ((bytes_received = recv(new_socket, buffer, BUFFER_SIZE, 0)) > 0) {
            fwrite(buffer, 1, bytes_received, file);
            if (buffer[bytes_received - 1] == '\n') {
                break;
            }
        }
        fclose(file);

        // Send data back to client
        file = fopen(FILE_PATH, "r");
        if (file == NULL) {
            syslog(LOG_ERR, "Failed to open data file for reading");
        } else {
            while (fgets(buffer, BUFFER_SIZE, file) != NULL) {
                send(new_socket, buffer, strlen(buffer), 0);
            }
            fclose(file);
        }

        // Close connection
        close(new_socket);
        syslog(LOG_INFO, "Closed connection from %s", inet_ntoa(address.sin_addr));
  
    }

    return 0;
}