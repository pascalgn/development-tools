SOURCES=$(shell ls *.sh *.py *.js)

PREFIX=$(HOME)/bin

all:
	shellcheck *.sh

develop: .checkprefix $(PREFIX) $(addprefix .link/, $(SOURCES))

.link/%: %
	chmod +x $<
	dos2unix $<
	ln -sf $(realpath $<) $(PREFIX)/$(basename $<)

install: .checkprefix $(PREFIX) $(addprefix .copy/, $(SOURCES))

.copy/%: %
	-test -L "$(PREFIX)/$(basename $<)" && rm -f "$(PREFIX)/$(basename $<)"
	cp $(realpath $<) $(PREFIX)/$(basename $<)
	dos2unix $(PREFIX)/$(basename $<)
	chmod +x $(PREFIX)/$(basename $<)

.checkprefix:
	@echo '$(PATH)' | grep -qE '(^|:)$(PREFIX)($|:)' || echo "$(PREFIX) is not in your PATH!" >&2

$(PREFIX):
	test -d $@ || mkdir -p $@
