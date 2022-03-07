SHELL=/bin/bash

BASH_COMPLETION_DIR?=/usr/share/bash-completion.d
BIN_DIR?=/usr/bin
DOC_DIR?=/usr/share/doc
MAN_DIR?=/usr/share/man
SHARE_DIR?=/usr/share
DEST_DIR?=


ifdef VERBOSE
  Q :=
else
  Q := @
endif


print-%:
	@echo $*=$($*)


clean:
	$(Q)rm -rf ./build
	$(Q)find . -name __pycache__ -exec rm -rf {} \;


venv:
	$(Q)virtualenv -p /usr/bin/python3 .venv
	$(Q)( \
		source .venv/bin/activate; \
		pip install -r requirements.txt; \
	)


test: .venv
	$(Q)( \
		source .venv/bin/activate; \
		python -m unittest; \
	)


deb: test build/package/DEBIAN/control
	$(Q)fakeroot dpkg-deb -b build/package build/coordcon.deb
	$(Q)lintian -Ivi build/coordcon.deb
	$(Q)dpkg-sig -s builder build/coordcon.deb
	@echo "coordcon.deb completed."


install: coordcon.bash-completion build/copyright build/changelog.gz build/coordcon.1.gz
	$(Q)install -Dm 0755 coordcon ${DEST_DIR}${BIN_DIR}/coordcon

	$(Q)install -Dm 0644 coordcon.bash-completion "${DEST_DIR}/${BASH_COMPLETION_DIR}"/coordcon.bash-completion

	$(Q)install -Dm 0644 build/changelog.gz ${DEST_DIR}${DOC_DIR}/coordcon/changelog.Debian.gz
	$(Q)install -Dm 0644 build/copyright ${DEST_DIR}${DOC_DIR}/coordcon/copyright

	$(Q)install -Dm 0644 build/coordcon.1.gz ${DEST_DIR}${MAN_DIR}/man1/coordcon.1.gz

	@echo "coordcon install completed."


uninstall:
	$(Q)rm -r ${DEST_DIR}${DOC_DIR}/coordcon
	$(Q)rm ${DEST_DIR}${BASH_COMPLETION_DIR}/coordcon.bash-completion
	$(Q)rm ${DEST_DIR}${BIN_DIR}/coordcon
	$(Q)rm ${DEST_DIR}${MAN_DIR}/man1/coordcon.1.gz

	@echo "coordcon uninstall completed."


build:
	$(Q)mkdir build

build/copyright: build
	$(Q)echo "Upstream-Name: coordcon" > build/copyright
	$(Q)echo "Source: https://github.com/jnphilipp/coordcon" >> build/copyright
	$(Q)echo "Files: *" >> build/copyright
	$(Q)echo "Copyright: 2022 J. Nathanael Philipp (jnphilipp) <nathanael@philipp.land>" >> build/copyright
	$(Q)echo "License: GPL-3+" >> build/copyright
	$(Q)echo " This program is free software: you can redistribute it and/or modify" >> build/copyright
	$(Q)echo " it under the terms of the GNU General Public License as published by" >> build/copyright
	$(Q)echo " the Free Software Foundation, either version 3 of the License, or" >> build/copyright
	$(Q)echo " any later version." >> build/copyright
	$(Q)echo "" >> build/copyright
	$(Q)echo " This program is distributed in the hope that it will be useful," >> build/copyright
	$(Q)echo " but WITHOUT ANY WARRANTY; without even the implied warranty of" >> build/copyright
	$(Q)echo " MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the" >> build/copyright
	$(Q)echo " GNU General Public License for more details." >> build/copyright
	$(Q)echo "" >> build/copyright
	$(Q)echo " You should have received a copy of the GNU General Public License" >> build/copyright
	$(Q)echo " along with this program. If not, see <http://www.gnu.org/licenses/>." >> build/copyright
	$(Q)echo " On Debian systems, the full text of the GNU General Public" >> build/copyright
	$(Q)echo " License version 3 can be found in the file" >> build/copyright
	$(Q)echo " '/usr/share/common-licenses/GPL-3'." >> build/copyright


build/copyright.h2m: build
	$(Q)echo "[COPYRIGHT]" > build/copyright.h2m
	$(Q)echo "This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version." >> build/copyright.h2m
	$(Q)echo "" >> build/copyright.h2m
	$(Q)echo "This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details." >> build/copyright.h2m
	$(Q)echo "" >> build/copyright.h2m
	$(Q)echo "You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/." >> build/copyright.h2m


build/changelog.gz: build
	$(Q)declare TAGS=(`git tag`); for ((i=$${#TAGS[@]};i>=0;i--)); do if [ $$i -eq 0 ]; then git log $${TAGS[$$i]} --no-merges --format="coordcon ($${TAGS[$$i]}-%h) unstable; urgency=medium%n%n  * %s%n    %b%n -- %an <%ae>  %aD%n" | sed "/^\s*$$/d" >> build/changelog; elif [ $$i -eq $${#TAGS[@]} ]; then git log $${TAGS[$$i-1]}..HEAD --no-merges --format="coordcon ($${TAGS[$$i-1]}-%h) unstable; urgency=medium%n%n  * %s%n    %b%n -- %an <%ae>  %aD%n" | sed "/^\s*$$/d" >> build/changelog; else git log $${TAGS[$$i-1]}..$${TAGS[$$i]} --no-merges --format="coordcon ($${TAGS[$$i]}-%h) unstable; urgency=medium%n%n  * %s%n    %b%n -- %an <%ae>  %aD%n" | sed "/^\s*$$/d" >> build/changelog; fi; done
	$(Q)cat build/changelog | gzip -n9 > build/changelog.gz


build/coordcon.1.gz: build build/copyright.h2m venv
	$(Q)( \
		source .venv/bin/activate; \
		help2man ./coordcon -i build/copyright.h2m -n "Convert geo coordinates." | gzip -n9 > build/coordcon.1.gz; \
	)


build/package/DEBIAN: build
	$(Q)mkdir -p build/package/DEBIAN


build/package/DEBIAN/md5sums: coordcon build/copyright build/changelog.gz build/coordcon.1.gz build/package/DEBIAN
	$(Q)make install DEST_DIR=build/package
	$(Q)mkdir -p build/package/DEBIAN
	$(Q)find build/package -type f -not -path "*DEBIAN*" -exec md5sum {} \; > build/md5sums
	$(Q)sed -e "s/build\/package\///" build/md5sums > build/package/DEBIAN/md5sums
	$(Q)chmod 0644 build/package/DEBIAN/md5sums


build/package/DEBIAN/control: build/package/DEBIAN/md5sums
	$(Q)echo "Package: coordcon" > build/package/DEBIAN/control
	$(Q)echo "Version: `git describe --tags`-`git log --format=%h -1`" >> build/package/DEBIAN/control
	$(Q)echo "Section: utils" >> build/package/DEBIAN/control
	$(Q)echo "Priority: optional" >> build/package/DEBIAN/control
	$(Q)echo "Architecture: all" >> build/package/DEBIAN/control
	$(Q)echo "Depends: python3 (<< 3.11), python3-utm" >> build/package/DEBIAN/control
	$(Q)echo "Installed-Size: `du -sk build/package/usr | grep -oE "[0-9]+"`" >> build/package/DEBIAN/control
	$(Q)echo "Maintainer: J. Nathanael Philipp (jnphilipp) <nathanael@philipp.land>" >> build/package/DEBIAN/control
	$(Q)echo "Homepage: https://github.com/jnphilipp/coordcon" >> build/package/DEBIAN/control
	$(Q)echo "Description: Commandline tool to convert geo coordinates" >> build/package/DEBIAN/control
	$(Q)echo " This tool can convert between utm (WGS84) coordinates and latitude/longitude." >> build/package/DEBIAN/control
