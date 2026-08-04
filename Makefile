PREFIX := /usr/local

SIB = $(filter-out %.tar.gz, $(wildcard sib-*)) sib lib.bash
PLM = $(wildcard plm/*)
VERSION = $(shell cat VERSION)
PN = sib-${VERSION}

tarball:
	tar --transform "s,^,${PN}/," -czvf ${PN}.tar.gz ${SIB} ${PLM} VERSION Makefile README.md

clean:
	rm *.tar.gz

install: uninstall
	mkdir -p ${DESTDIR}${PREFIX}/libexec/sib-core
	cp -R ${SIB} ${PLM} VERSION ${DESTDIR}${PREFIX}/libexec/sib-core
	ln -sf	../libexec/sib-core/sib ${DESTDIR}${PREFIX}/bin/sib
	chmod 755 ${DESTDIR}${PREFIX}/bin/sib

uninstall:
	rm -rf -- ${DESTDIR}${PREFIX}/libexec/sib-core
	rm -f -- ${DESTDIR}${PREFIX}/bin/sib

.PHONY: install uninstall tarball clean
