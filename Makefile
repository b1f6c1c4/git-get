SHELL=/bin/bash -o pipefail
REPORTS=$(patsubst tests/%,report/%,$(wildcard tests/**/*.test))

test: $(REPORTS)

report/%: tests/% git-get git-gets
	mkdir -p "$$(dirname "$@")"
	./run-test "$<" 2>&1 | tee "$@"

clean:
	rm -rf report/

.PHONY: test clean
