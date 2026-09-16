PORT ?= 8000

build-web:
	./scripts/build_web.sh

test:
	./scripts/test.sh

format:
	odinfmt . -w

serve-web:
	python3 -m http.server $(PORT) --directory build/web

.PHONY: build-web test format serve-web
