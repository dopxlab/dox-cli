.PHONY: build bundle

build:
	chmod +x bin/dox
	tar -czf dox.tar.gz bin/ lib/ actions/ configure/ custom/

bundle:
	cat bin/dox lib/configure.sh lib/action.sh > dox.sh
	chmod +x dox.sh
