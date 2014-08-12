G_CFLAGS=-W -Wall -ansi -Wno-missing-field-initializers -O3 -Wno-deprecated -std=c++11
G_LDFLAGS=
G_INCLUDES=-I./ -I../ -I../raindance -I../raindance/Lib/glm-0.9.5.4

PYTHON_CFLAGS = `python2.7-config --cflags | sed s/"-mno-fused-madd"//g`
PYTHON_LDFLAGS = `python2.7-config --ldflags`

BINARY=graphiti
DIST=$(binary)-$(shell date +"%Y%m%d")

ifeq ($(OS), Windows_NT)
	CC=g++
	CFLAGS=$(G_CFLAGS) $(PYTHON_CFLAGS) -m32
	INCLUDES=$(G_INCLUDES) -I/mingw32/include -L/mingw32/bin -L/mingw32/lib
	LDFLAGS=$(G_LDFLAGS) $(PYTHON_LDFLAGS) -lm -lfreeglut -lopengl32 -lglu32 -lglew32
else
	UNAME := $(shell uname -s)
	ifeq ($(UNAME), Darwin)
		CC=clang++
		CFLAGS=$(G_CFLAGS) $(PYTHON_CFLAGS) -stdlib=libc++
		INCLUDES=$(G_INCLUDES)
		LDFLAGS=$(G_LDFLAGS) $(PYTHON_LDFLAGS) -framework GLUT -framework OpenGL -framework OpenCL
	endif
	ifeq ($(UNAME), Linux)
		CC=g++
		CFLAGS=$(G_CFLAGS) $(PYTHON_CFLAGS)
		INCLUDES=$(G_INCLUDES)
		LDFLAGS=$(G_LDFLAGS) $(PYTHON_LDFLAGS) -lm -lglut -lGL -lGLU -lGLEW -lOpenCL
	endif
endif

DUETTO_CC=../duetto/bin/clang++
DUETTO_CFLAGS=-O3

EMS_CC=../emscripten/1.16.0/em++
EMS_CFLAGS=-std=c++11
EMS_INCLUDES=

JS_EXPORT="\
[\
    '_create', '_destroy', '_initialize', '_start',\
	'_registerScript',\
	\
	'_setAttribute',\
	\
	'_addNode', '_removeNode', '_countNodes', '_getNodeID',\
	'_setNodeLabel', '_getNodeLabel',\
	'_setNodeMark', '_getNodeMark',\
	'_setNodeWeight', '_getNodeWeight',\
	'_setNodeAttribute',\
	\
	'_addLink', '_removeLink', '_countLinks', '_getLinkID',\
	'_getLinkNode1', '_getLinkNode2',\
	'_setLinkAttribute',\
	\
	'_countSelectedNodes', '_getSelectedNode',\
]"

all: pack
	@echo "--- Compiling release version for $(UNAME) ---"
	$(CC) $(CFLAGS) $(INCLUDES) Main.cc -o $(BINARY) $(LDFLAGS)

debug: pack
	@echo "--- Compiling debug version for $(UNAME) ---"
	$(CC) $(CFLAGS) -g $(INCLUDES) Main.cc -o $(BINARY) $(LDFLAGS)

pack:
	( cd ../raindance && make )
	@echo "--- Packing Resources ---"
	. pack.sh

web:
	@echo "--- Compiling web version with Emscripten ---"
	$(EMS_CC) $(EMS_CFLAGS) $(EMS_INCLUDES) Main.cc -s FULL_ES2=1 -s TOTAL_MEMORY=268435456 -o Web/$(BINARY).js -s EXPORTED_FUNCTIONS=$(JS_EXPORT)

duetto:
	@echo "--- Compiling for Web with Duetto ---"
	$(DUETTO_CC) $(DUETTO_CFLAGS) $(INCLUDES) -target duetto Main.cc -o Web/$(WEB_OUT)

clean:
	@echo "--- Cleaning ---"
	( cd ../raindance && make clean )
	rm -rf *~
	rm -rf */*~
	rm -rf *.pyc */*.pyc
	rm -rf Pack.hh
	rm -rf Web/$(BINARY).js
	rm -rf Web/$(BINARY).map
	rm -rf $(BINARY)
	rm -rf $(BINARY).dSYM

dist: clean native
	@echo "--- Making distributable tarball ---"
	rm -rf $(DIST)
	mkdir $(DIST)
	cp ${NATIVE_OUT} $(DIST)/
	cp -r Scripts $(DIST)/
	rm -rf $(DIST)/Scripts/*.pyc ${DIST}/.DS_Store
	cp LICENSE $(DIST)/

	@echo "--- Copying external libraries ---"
	mkdir $(DIST)/Lib
	cp Lib/pygeoip-0.2.7.tar.gz $(DIST)/Lib
	cp Lib/GeoLiteCity.dat $(DIST)/Lib
	cp Lib/networkx-1.8.1.zip $(DIST)/Lib

	@echo "--- Removing temporary files ---"
	zip -r $(DIST).zip $(DIST)
	rm -rf $(DIST)
