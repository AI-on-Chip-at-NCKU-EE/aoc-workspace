BIN := test

CC := g++
CFLAGS := -Wall -Wextra

SYSTEMC_HOME := /opt/systemc-2.3.4

ARCH := $(shell uname -m)
ifeq ($(ARCH), aarch64)
    lib := lib-linuxaarch64
else
    lib := lib-linux64
endif

INCLUDE_DIR := ${SYSTEMC_HOME}/include
LINK_DIR := ${SYSTEMC_HOME}/${lib}
BUILD_DIR := build

SRC := test.cpp
OBJ := $(BUILD_DIR)/$(SRC:.cpp=.o)

.PHONY: all clean

all: $(BUILD_DIR)/$(BIN)
	./$(BUILD_DIR)/$(BIN)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -I$(INCLUDE_DIR) -o $@

$(BUILD_DIR)/$(BIN): $(OBJ)
	$(CC) $^ -L${LINK_DIR} -lsystemc -Wl,-rpath,$(LINK_DIR) -o $@

clean:
	rm -rf $(BUILD_DIR)