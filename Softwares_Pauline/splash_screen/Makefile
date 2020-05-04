#CC=i386-pc-linux-gcc
CC=gcc

UNAME := $(shell uname)

INCLUDES = -I./inc

DEBUG ?= 0

ifeq ($(DEBUG), 1)
	CFLAGS=-O0 $(INCLUDES) -Wall -g -DDEBUG #-fsanitize=address -fno-omit-frame-pointer
	LDFLAGS= -lc -lm -ldl -lpthread #-lasan
else
	CFLAGS=-O3 $(INCLUDES) -Wall
	LDFLAGS= -lc -lm -ldl -lpthread -s
endif

sources := $(wildcard src/*.c)
objects := $(sources:src/%.c=obj/%.o)

LDFLAGS += -Wl,-rpath=. -Wl,-Map,foo.map

EXEC=splash_screen

all: output_dir $(EXEC)

splash_screen:  $(objects)
	${CC} -o $@    $^ $(LDFLAGS)

$(objects): obj/%.o: src/%.c
	${CC} -o $@ $^ -c $(CFLAGS)

clean:
	rm -rf obj/*.o
	rm -rf obj/*.so
	rm -rf $(EXEC)
	rm -rf *.map

mrproper: clean
	-rm -fR obj

output_dir:
	@mkdir -p obj

.PHONY: clean mrproper
