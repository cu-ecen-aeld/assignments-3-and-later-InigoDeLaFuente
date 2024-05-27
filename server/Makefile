# Compiler options
CC := gcc
CFLAGS := -Wall -Wextra -Werror
LDFLAGS :=

# Application name
APP := aesdsocket

# Source files
SRC := aesdsocket.c

# Object files
OBJ := $(SRC:.c=.o)

# Cross-compiler prefix
CROSS_COMPILE ?=

# Native build platform
ifeq ($(CROSS_COMPILE),)
    TARGET :=
else
    TARGET := $(CROSS_COMPILE)
endif

# Default target
.PHONY: all
all: $(APP)

# Rule to build the application
$(APP): $(OBJ)
	$(TARGET)$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

# Rule to compile C source files
%.o: %.c
	$(TARGET)$(CC) $(CFLAGS) -c -o $@ $<

# Clean target
.PHONY: clean
clean:
	rm -f $(APP) $(OBJ)
