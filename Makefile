ifneq (,$(wildcard $(dirname $(which bats))/../lib/bash/.))
	BATS_HELPERS_LOCATION ?= $(dirname $(which bats))/../lib/bash
else
	BATS_HELPERS_LOCATION ?= $(shell pwd)/test/bats_helpers
endif

test:
	BATS_HELPERS_LOCATION="$(BATS_HELPERS_LOCATION)" bats test || true

.PHONY: test
