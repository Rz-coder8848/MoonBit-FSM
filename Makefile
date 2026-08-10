.PHONY: all test build benchmark run clean

all: test build benchmark

test:
	moon test

build:
	moon build

benchmark:
	moon run benchmarks

run:
	moon run cmd/fsm-cli

clean:
	moon clean
