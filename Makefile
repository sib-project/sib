PREFIX := /usr/local

SIB = sib $(wildcard sib-*) lib.bash
PLM = $(wildcard plm/*)

.PHONY: install uninstall

install: uninstall
	mkdir -p ${DESTDIR}${PREFIX}/libexec/sib-core
	cp -R ${SIB} ${PLM} VERSION ${DESTDIR}${PREFIX}/libexec/sib-core
	ln -sf  ../libexec/sib-core/sib ${DESTDIR}${PREFIX}/bin/sib
	chmod 755 ${DESTDIR}${PREFIX}/bin/sib

uninstall:
	rm -rf -- ${DESTDIR}${PREFIX}/libexec/sib-core
	rm -f -- ${DESTDIR}${PREFIX}/bin/sib
