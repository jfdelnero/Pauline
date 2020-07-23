#CC=i386-pc-linux-gcc
CC=gcc

UNAME := $(shell uname)

INCLUDES = -I./inc

DEBUG ?= 0
LIBS=

ifeq ($(DEBUG), 1)
	CFLAGS=-O0 $(INCLUDES) -Wall -I ../wsServer/include/ -g -DDEBUG #-fsanitize=address -fno-omit-frame-pointer
	LDFLAGS= -lc -lm -ldl -lpthread ${TARGET_ROOTFS}/lib/libhxcfe.so ../wsServer/libws.a
else
	CFLAGS=-O3 $(INCLUDES) -Wall -I ../wsServer/include/
	LDFLAGS= -lc -lm -ldl -lpthread ${TARGET_ROOTFS}/lib/libhxcfe.so ../wsServer/libws.a -s
endif

sources := $(wildcard src/*.c)
objects := $(sources:src/%.c=obj/%.o)

LDFLAGS += -Wl,-rpath=. -Wl,-Map,foo.map

EXEC=pauline

all: output_dir $(EXEC)

pauline:  $(objects)
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
