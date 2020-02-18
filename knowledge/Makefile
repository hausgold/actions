MAKEFLAGS += --warn-undefined-variables -j1
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY:

# Directories
DIST_DIRS ?= dist

# Host binaries
AWK ?= awk
BASH ?= bash
CHMOD ?= chmod
CP ?= cp
CUT ?= cut
ECHO ?= echo
FIND ?= find
GREP ?= grep
HEAD ?= head
LS ?= ls
MKDIR ?= mkdir
MV ?= mv
NPM_CHECK_DEPENDENCIES ?= check-dependencies
NPM ?= npm
NPROC ?= nproc
PRINTF ?= printf
RM ?= rm
TAIL ?= tail
TEE ?= tee
TEST ?= test
WC ?= wc
XARGS ?= xargs

all:
	# Knowledge
	#
	# install         Install the dependencies
	# build           Build all distribution files

install:
	# Install the dependencies
	@$(NPM_CHECK_DEPENDENCIES) || $(NPM) install

build: install
	# Build all distribution files
	@$(NPM) run build
