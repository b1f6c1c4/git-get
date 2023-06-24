SHELL=/bin/bash -o pipefail
REPORTS=$(patsubst tests/%,report/%,$(wildcard tests/**/*.test))
COVERAGES=$(patsubst tests/%,coverage/%,$(wildcard tests/**/*.test))

test: $(REPORTS)

cover: coverage/merged/index.html

coverage/merged/index.html: $(COVERAGES)
	kcov --coveralls-id=$(COVERALLS_REPO_TOKEN) --merge coverage/merged $^

report/%: tests/% git-get git-gets
	mkdir -p "$$(dirname "$@")"
	./run-test "$<" 2>&1 | tee "$@"

coverage/%: tests/% git-get git-gets
	mkdir -p "$$(dirname "$@")"
	./run-test "$<" "$@" || { rm -rf "$@"; false; }

clean:
	rm -rf report/ coverage/

.PHONY: test cover clean

.DELETE_ON_ERROR: $(REPORTS)
