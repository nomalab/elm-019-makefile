PATH  := node_modules/.bin:$(PATH)
SHELL := /bin/bash
.DEFAULT_GOAL := all
.PHONY: all clean deps help installIfNot

# Arguments
mode  := prod
quiet := false

##
## Commands
##

all: clean deps dist

dist: dist/Private.js dist/Public.js
	$(call action, "DONE")

watch:
	$(call action, "Watching")
	@ livereload dist/ \
		& chokidar 'src/**' --initial --silent \
			-c 'make -s dist mode=dev'

ifeq ($(mode), dev)
cache: dist/Private.bundle.js dist/Private.elm.js dist/Public.bundle.js dist/Public.elm.js
endif

clean:
	@ rm -rf dist elm-stuff node_modules
	$(call action, "Cleaned")

distclean:
	@ rm -rf dist
	$(call action, "Cleaned dist")

deps:
	$(call action, "Installing...")
	@ npm i

##
## Sources
##

elmSource     := src/%.elm
allElmSources := src/*.elm
jsSource      := src/%.js
allJsSources  := src/*.js
mainFile      := dist/%.js
elmOutput     := dist/%.elm.js
bundle        := dist/%.bundle.js
debug         := dist/%.html

##
## Files dependencies & build
##

$(mainFile): $(elmOutput) $(bundle)
	$(call stl, $*, "Concatenating")
ifeq ($(mode), prod)
	@ uglifyjs $^ -mc 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9"' -o $@
else
	@ cat $^ > $@
endif

$(elmOutput): $(elmSource) $(allElmSources)
	$(call stl, $*, "Compiling")
ifeq ($(mode), prod)
	@ ./bin/elm make $< --optimize --output=$@
else
	@ ./bin/elm make $< --output=$@
endif

$(bundle): $(jsSource) $(allJsSources)
	$(call stl, $*, "Bundling")
	@ browserify $< -o $@


##
## Help & Formatting
##

help:
	$(call action, "Build the front")
	$(call help, "dist   ","build files for production")
	$(call help, "debug  ","build files for debug")
	@ echo ""
	$(call help, "clean  ","remove temporary files")
	$(call help, "watch  ","watch & compile files")
	$(call help, "deps   ","install dependencies")
	$(call help, "help   ","this")
	@ echo ""
	@ echo ""
	@ echo " *defaults : quiet=false mode=prod"
	@ echo ""

ifneq ($(quiet), true)
define stl
@ echo ""
@ tput setaf 4
@ tput bold
@ echo -n " :"
@ printf "%-.10s" "$1                    "
@ echo -n ": "
@ tput setaf 7
@ echo -n "$2"
@ tput sgr0
endef
endif

define action
	@ echo ""
	@ tput setaf 4
	@ tput bold
	@ echo -n " : "
	@ tput setaf 7
	@ echo -n $1
	@ tput sgr0
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
