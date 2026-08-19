include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LSSecondsPrefs

LSSecondsPrefs_FILES = LSSRootListController.m
LSSecondsPrefs_FRAMEWORKS = UIKit
LSSecondsPrefs_PRIVATE_FRAMEWORKS = Preferences
LSSecondsPrefs_INSTALL_PATH = /Library/PreferenceBundles
LSSecondsPrefs_CFLAGS = -fobjc-arc
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
LSSecondsPrefs_LIBRARIES = roothide
endif
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
LSSecondsPrefs_CFLAGS += -DLSSECONDS_PACKAGE_SCHEME_ROOTLESS=1
endif

include $(THEOS_MAKE_PATH)/bundle.mk
