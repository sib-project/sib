PREFIX := /usr/local
SUFFIX := libexec/sib-core
COREPREFIX = ${DESTDIR}${PREFIX}/${SUFFIX}

SIB = sib $(wildcard sib-*) lib.bash
PLM = $(wildcard plm/*)

.PHONY: install uninstall

install: uninstall
	mkdir -p ${COREPREFIX}/plm
	cp -R ${SIB} ${PLM} VERSION ${COREPREFIX}
	ln -sf  ../${SUFFIX}/sib ${DESTDIR}${PREFIX}/bin/sib
	chmod 755 ${DESTDIR}${PREFIX}/bin/sib

uninstall:
	rm -rf -- ${COREPREFIX}
	rm -f -- ${DESTDIR}${PREFIX}/bin/sib
