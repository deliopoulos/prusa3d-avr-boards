#
#  Prusa3D Arduino IDE Module makefile.
#
PACKAGE_NAME := prusa3d
PACKAGE_VERSION := 1.0.0
ROOT_PATH := .
BUILD_DIR := ../$(PACKAGE_NAME)-release
SOURCE_FOLDER := $(ROOT_PATH)/$(PACKAGE_NAME)
PACKAGE_FOLDER := $(BUILD_DIR)/$(PACKAGE_NAME)

PLATFORM_FILE := platform.txt
EXTRA_FILES := avrdude.conf \
	boards.txt

BOOTLOADERS := caterina/*.hex \
	stk500v2-prusa/*.hex

VARIANTS := prusa_mm_control/* \
	rambo/*

SUBDIRS := $(addprefix bootloaders/,$(BOOTLOADERS))
SUBDIRS += $(addprefix variants/,$(VARIANTS))


.SUFFIXES: .tar.bz2

#============================================================================

# Define programs and commands.
SHELL   = sh
MKDIR ?=mkdir -p
REMOVE ?=rm -rf
COPY ?=cp
SHASUM ?=sha256sum
CAT ?=cat
TAR ?=tar -cjf

DEBUG_Makefile ?=0
ifeq ($(strip $(DEBUG_Makefile)),0)
MAKE_QUIET_BUILD?=@
MAKE_QUIET_LINK?=@
endif

# Define Messages
# English
MSG_ERRORS_NONE = Errors: none
MSG_BEGIN = -------- begin --------
MSG_END = --------  end  --------
MSG_COPY_SUBDIRS = Copying $@
MSG_EXTRA_FILES = Copying $@
MSG_PLATFORM_FILE = Buildind $(PLATFORM_FILE)
MSG_BUILDIND_TAR = Creating $(PACKAGE_FILENAME)
MSG_BUILDIND_JSON = Buildind package_index.json.template
MSG_CLEANING = Cleaning project:

# -----------------------------------------------------------------------------

PACKAGE_FILENAME=$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.bz2

ifeq ($(MAKECMDGOALS),post-build)
	PACKAGE_CHKSUM := $(firstword $(shell $(SHASUM) ${BUILD_DIR}/${PACKAGE_FILENAME}))
	PACKAGE_SIZE := $(firstword $(shell wc -c ${BUILD_DIR}/${PACKAGE_FILENAME}))
endif

.PHONY: all begin end $(SUBDIRS) $(EXTRA_FILES) version archive post-build build_json clean clean_list

all: begin clean_list $(SUBDIRS) $(EXTRA_FILES) version archive end
	$(MAKE) --no-print-directory post-build

begin:
	@echo
	@echo $(MSG_BEGIN)

end:
	@echo
	@echo $(MSG_END)

$(SUBDIRS):
	@echo
	@echo $(MSG_COPY_SUBDIRS)
		$(MAKE_QUIET_BUILD)$(MKDIR) $(PACKAGE_FOLDER)/$(@D)
		$(MAKE_QUIET_BUILD)$(COPY) $(SOURCE_FOLDER)/$@ $(PACKAGE_FOLDER)/$(@D)/

$(EXTRA_FILES) :
	@echo
	@echo $(MSG_EXTRA_FILES)
	$(MAKE_QUIET_BUILD)$(COPY) $(SOURCE_FOLDER)/$@ $(PACKAGE_FOLDER)/
	
version :
	@echo
	@echo $(MSG_PLATFORM_FILE)
	$(MAKE_QUIET_BUILD)$(CAT) $(PACKAGE_NAME)/$(PLATFORM_FILE) | sed s/%%VERSION%%/$(PACKAGE_VERSION)/ > $(PACKAGE_FOLDER)/$(PLATFORM_FILE)

archive :
	@echo
	@echo $(MSG_BUILDIND_TAR)
	@echo "This is an Prusa3D AVR Boards version ${PACKAGE_VERSION} Release" > ${PACKAGE_FOLDER}/README.TXT
	@echo >> ${PACKAGE_FOLDER}/README.TXT
	@echo "For Source code see https://github.com/deliopoulos/prusa3d-avr-boards" >> ${PACKAGE_FOLDER}/README.TXT
	$(MAKE_QUIET_BUILD)$(TAR) "$(BUILD_DIR)/$(PACKAGE_FILENAME)" -C "$(BUILD_DIR)" "$(PACKAGE_NAME)"


post-build : begin build_json end

build_json :
	@echo
	@echo $(MSG_BUILDIND_JSON)
	$(MAKE_QUIET_BUILD)$(CAT) extras/package_index.json.template | sed s/%%VERSION%%/${PACKAGE_VERSION}/ | sed s/%%FILENAME%%/${PACKAGE_FILENAME}/ | sed s/%%CHECKSUM%%/${PACKAGE_CHKSUM}/ | sed s/%%SIZE%%/${PACKAGE_SIZE}/ > ${BUILD_DIR}/package_${PACKAGE_NAME}_index.json

# Target: clean project.
clean: begin clean_list end

clean_list :
	@echo
	@echo $(MSG_CLEANING)
	$(REMOVE) $(PACKAGE_FOLDER)
	$(REMOVE) $(BUILD_DIR)/$(PACKAGE_NAME)-*.tar.bz2 \
			$(BUILD_DIR)/package_$(PACKAGE_NAME)_*.json
