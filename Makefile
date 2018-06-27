PATH  := node_modules/.bin:$(PATH)
SHELL := /bin/bash

# TODO: when release, use npm's elm

##
## Sources
##

sourceElm       := src/%.elm
allElm          := src/*.elm
sourceJs        := src/%.js
allJs           := src/*.js
debugElmDist    := dist/%.elm.js
browserifyDist  := dist/%.bdl.js
debugDist       := dist/%.js
minifiedElmDist := dist/%.elm.min.js
productionDist  := dist/%.min.js
npmBinDeps      := elm browserify livereload uglify-js chokidar

##
## Files dependencies & build
##

$(debugElmDist): $(sourceElm) $(allElm)
	$(call stl, $*, "Compiling")
	./bin/elm make $< --output=$@

$(minifiedElmDist): $(debugElmDist)
	$(call stl, $*, "Optimilzing")
	./bin/elm make src/$*.elm --optimize --output=$@

$(debugDist): $(debugElmDist) $(browserifyDist)
	$(call stl, $*, "Concatenating")
	cat $^ > $@

$(browserifyDist): $(sourceJs) $(allJs)
	$(call stl, $*, "Bundling")
	browserify $< -o $@

$(productionDist): $(minifiedElmDist) $(browserifyDist)
	$(call stl, $*, "Minifying")
	uglifyjs $^ -cm -o $@


##
## Commands
##

all: install debug prod

prod: dist/Private.min.js dist/Public.min.js

debug: dist/Private.js dist/Public.js

blundle: dist/Private.bdl.js dist/Public.bdl.js

makeElm: dist/Private.elm.js dist/Public.elm.js

watch:
	$(call action, "Watching...")
	@ livereload dist/ \
		& chokidar 'src/**.elm' --initial -c 'make debug'

clean:
	@ rm -rf dist elm-stuff
	$(call success, "Cleaned")

ifeq ($(wildcard package.json),) 
install: $(npmDependencies)
else
install:
	$(call stl, $@, "Installing:")
	@ npm i
	@ rm -f $(bundle)
	@ make -s $(bundle)
endif

help:
	$(call success, "Build the front")
	$(call help, "prod   ","build files for prod")
	$(call help, "debug  ","build files for debug")
	$(call help, "bundle ","bundle with browserify")
	@ echo ""
	$(call help, "clean  ","remove temporary files")
	$(call help, "watch  ","watch & compile files")
	$(call help, "install","install dependencies")
	$(call help, "help   ","this")
	@ echo ""
	@ echo ""


##
## Npm dependencies
##

chokidar:
	npm i chokidar-cli

$(npmDependencies):
	npm i $@


##
## Format text
##

define stl
	@ echo ""
	@ tput setaf 3
	@ tput bold
	@ echo -n ":"
	@ tput setaf 6
	@ echo -n $2
	@ tput setaf 3
	@ echo -n ":"
	@ echo -n $1
	@ tput sgr0
	@ echo ""
endef

define success
	@ echo ""
	@ echo -n "  "
	@ tput bold
	@ tput setaf 2
	@ echo -n $1
	@ tput sgr0
	@ echo ""
	@ echo ""
endef

define action
	@ echo ""
	@ echo -n "  "
	@ tput bold
	@ tput setaf 6
	@ echo -n $1
	@ tput sgr0
	@ echo ""
	@ echo ""
endef

define help
	@ echo ""
	@ echo -n " > "
	@ tput bold
	@ tput setaf 6
	@ echo -n $1
	@ tput sgr0
	@ echo -n " : "
	@ echo -n $2
endef

.PHONY: all clean install help $(npmDependencies)
