MAKEFLAGS += --warn-undefined-variables -j8
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY:

# Dynamic recipe names
NON_ACTIONS ?= lib doc
ACTIONS ?= $(filter-out $(NON_ACTIONS),$(patsubst %/,%,\
	$(patsubst ./%,%,$(sort $(dir $(wildcard ./*/*))))))
INSTALL_ACTIONS := $(ACTIONS:%=install-%)
BUILD_ACTIONS := $(ACTIONS:%=build-%)

all:
	# HAUSGOLD Actions
	#
	# install       Install all actions dependencies
	# build         Rebuild all actions

$(INSTALL_ACTIONS): ACTION = $(@:install-%=%)
$(INSTALL_ACTIONS):
	@$(MAKE) -C $(ACTION) install

$(BUILD_ACTIONS): ACTION = $(@:build-%=%)
$(BUILD_ACTIONS):
	@$(MAKE) -C $(ACTION) build

install: $(INSTALL_ACTIONS)
build: $(BUILD_ACTIONS)
