.PHONY: release-macos
release-macos:
	./scripts/release-macos.sh

.PHONY: notary-smoke-test
notary-smoke-test:
	./scripts/notary-smoke-test.sh
