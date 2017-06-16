SOURCES=$(shell ls *.sh *.py)

PREFIX=$(HOME)/bin

all:

develop: $(PREFIX) $(addprefix .link/, $(SOURCES))

.link/%: %
	ln -sf $(realpath $<) $(PREFIX)/$(basename $<)

install: $(PREFIX) $(addprefix .copy/, $(SOURCES))

.copy/%: %
	test -L "$(PREFIX)/$(basename $<)" || rm -f "$(PREFIX)/$(basename $<)"
	cp $(realpath $<) $(PREFIX)/$(basename $<)
	dos2unix $(PREFIX)/$(basename $<)
	chmod +x $(PREFIX)/$(basename $<)

$(PREFIX):
	test -d $@ || mkdir -p $@
