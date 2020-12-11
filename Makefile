MAKEFLAGS += --warn-undefined-variables -j8
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY:

# Host Binaries
CD ?= cd
NPM ?= npm

# Dynamic recipe names
NON_ACTIONS ?= lib doc
ACTIONS ?= $(filter-out $(NON_ACTIONS),$(patsubst %/,%,\
	$(patsubst ./%,%,$(sort $(dir $(wildcard ./*/*))))))
ALL_ACTIONS ?= $(ACTIONS) lib
INSTALL_ACTIONS := $(ACTIONS:%=install-%)
BUILD_ACTIONS := $(ACTIONS:%=build-%)
CLEAN_ACTIONS := $(ALL_ACTIONS:%=clean-%)
UPDATE_ACTIONS := $(ALL_ACTIONS:%=update-%)

all:
	# HAUSGOLD Actions
	#
	# install       Install all actions dependencies
	# build         Rebuild all actions
	# clean         Clean all temporary files and dependencies
	# update        Update all Node.js dependencies

$(INSTALL_ACTIONS): ACTION = $(@:install-%=%)
$(INSTALL_ACTIONS):
	@$(MAKE) -C $(ACTION) install

$(BUILD_ACTIONS): ACTION = $(@:build-%=%)
$(BUILD_ACTIONS):
	@$(MAKE) -C $(ACTION) build

$(CLEAN_ACTIONS): ACTION = $(@:clean-%=%)
$(CLEAN_ACTIONS):
	# Clean the temporary files and dependencies of $(ACTION)
	@$(RM) -rf $(ACTION)/node_modules

$(UPDATE_ACTIONS): ACTION = $(@:update-%=%)
$(UPDATE_ACTIONS):
	# Update all Node.js dependencies $(ACTION)
	@$(CD) "$(ACTION)" && $(NPM) update

install: $(INSTALL_ACTIONS)
build: $(BUILD_ACTIONS)
update: $(UPDATE_ACTIONS)
clean: $(CLEAN_ACTIONS)
