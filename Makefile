#
# build web based version of Mindwheel using dosbox compiled with emscripten
#

# http://www.imagemagick.org/discourse-server/viewtopic.php?f=2&t=11137&p=35692
# http://www.libpng.org/pub/png/libpng.html
# http://www.ijg.org/files/
# http://download.savannah.gnu.org/releases/freetype/
# http://www.freedesktop.org/software/fontconfig/release/
# http://download.osgeo.org/libtiff/

LIB_TOOLS := $(shell pwd;)
LIB_BUILD_ROOT := $(LIB_TOOLS)/root
LIB_PACKAGE_ROOT := $(LIB_TOOLS)/package
LIB_PACKAGE_SRC := $(LIB_TOOLS)/mindwheeldos

all:
	@echo "Targets:"
	@echo "  build"
	@echo "  clean"

build: build_dosbox
	$(MAKE) package_mindwheel
	@echo Done!

clean:
	@rm -Rf $(LIB_BUILD_ROOT)
	@rm -Rf $(LIB_PACKAGE_ROOT)
	@rm -Rf emsdk-portable.tar.gz
	@rm -Rf em-dosbox
	@rm -Rf emsdk_portable
	@echo Cleaned!

get_libs:
	@if [ ! -f emsdk-portable.tar.gz ]; then \
		curl -O --insecure https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz; \
	fi;
	@if [ ! -d em-dosbox ]; then \
		git clone https://github.com/dreamlayers/em-dosbox.git; \
	fi;
	
setup_libs: get_libs
	@if [ ! -d $(LIB_BUILD_ROOT) ]; then \
		mkdir -p $(LIB_BUILD_ROOT); \
	fi;
	@if [ ! -d $(LIB_BUILD_ROOT)/emsdk_portable ]; then \
		tar xzf emsdk-portable.tar.gz; \
		cp -R emsdk_portable $(LIB_BUILD_ROOT)/emsdk_portable; \
		$(LIB_BUILD_ROOT)/emsdk_portable/emsdk update; \
		$(LIB_BUILD_ROOT)/emsdk_portable/emsdk install latest; \
		$(LIB_BUILD_ROOT)/emsdk_portable/emsdk activate latest; \
	fi;
	@if [ ! -d $(LIB_BUILD_ROOT)/em-dosbox ]; then \
		cp -R em-dosbox $(LIB_BUILD_ROOT)/em-dosbox; \
	fi;

lib_root:
	@echo $(LIB_BUILD_ROOT)

# Check make commands $(MAKELEVEL) which is an interal recursive variable
ifeq ($(MAKELEVEL), 0)
build_dosbox: setup_libs
	bash -c "source $(LIB_BUILD_ROOT)/emsdk_portable/emsdk_env.sh; \
	for var in \$$(compgen -v); do export \$$var; done; \
	$(MAKE) -C $(LIB_BUILD_ROOT)/em-dosbox -f $(LIB_TOOLS)/Makefile build_dosbox"
else
build_dosbox:
	./autogen.sh
	emconfigure ./configure --with-sdl2=no
	$(MAKE)
endif

package_mindwheel:
	@rm -rdf $(LIB_PACKAGE_ROOT)
	@mkdir -p $(LIB_PACKAGE_ROOT)
	@mkdir -p $(LIB_PACKAGE_ROOT)/files
	@cp $(LIB_PACKAGE_SRC)/ADISK.OBJ $(LIB_PACKAGE_ROOT)/files/.
	@cp $(LIB_PACKAGE_SRC)/Go.exe $(LIB_PACKAGE_ROOT)/files/.
	@cp $(LIB_PACKAGE_SRC)/SIDE.TXT $(LIB_PACKAGE_ROOT)/files/.
	@echo "[dosbox]" > $(LIB_PACKAGE_ROOT)/files/dosbox.conf
	@echo "machine=svga_s3" >> $(LIB_PACKAGE_ROOT)/files/dosbox.conf
	@echo "[dos]" >> $(LIB_PACKAGE_ROOT)/files/dosbox.conf
	@echo "keyboardlayout=uk" >> $(LIB_PACKAGE_ROOT)/files/dosbox.conf
	@cp $(LIB_BUILD_ROOT)/em-dosbox/src/dosbox.js $(LIB_PACKAGE_ROOT)/.
	@cp $(LIB_BUILD_ROOT)/em-dosbox/src/dosbox.html.mem $(LIB_PACKAGE_ROOT)/.
	@cp $(LIB_BUILD_ROOT)/em-dosbox/src/dosbox.html $(LIB_PACKAGE_ROOT)/.
	@cp $(LIB_BUILD_ROOT)/em-dosbox/src/packager.py $(LIB_PACKAGE_ROOT)/.
	$(MAKE) -C $(LIB_PACKAGE_ROOT) -f $(LIB_TOOLS)/Makefile run_packer

run_packer:
	./packager.py mindwheel files Go.exe
