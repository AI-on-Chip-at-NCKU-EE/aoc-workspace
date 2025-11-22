BIN := main

CC := gcc

CFLAGS := -Wall -Wextra -O2
INCLUDE_DIR := .
BUILD_DIR := build

SRC := main.c
OBJ := $(BUILD_DIR)/$(SRC:.c=.o)

.PHONY: all run clean

all: run

$(BUILD_DIR)/$(BIN): $(OBJ)
	$(CC) $^ -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -I$(INCLUDE_DIR) -o $@

run: $(BUILD_DIR)/$(BIN)
	./$(BUILD_DIR)/$(BIN)

clean:
	rm -rf $(BUILD_DIR)
