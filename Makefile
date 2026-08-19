ARCHS ?= arm64 arm64e
TARGET ?= iphone:clang:14.5:14.5
export THEOS_PACKAGE_SCHEME ?= roothide

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LSSeconds

LSSeconds_FILES = Tweak.xm LSSeconds.m
LSSeconds_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += lssecondsprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
