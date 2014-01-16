GO_EASY_ON_ME = 1

TARGET := iphone:clang
SDKVERSION_armv7 = 6.0
SDKVERSION_armv64 = 7.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION := 6.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 := 7.0
ARCHS := armv7 armv7s arm64

BUNDLE_NAME = PanoPreferences
PanoPreferences_FILES = Preferences.mm
PanoPreferences_FRAMEWORKS = UIKit
PanoPreferences_PRIVATE_FRAMEWORKS = Preferences
PanoPreferences_INSTALL_PATH = /Library/PreferenceBundles

include ../theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PanoPreferences.plist$(ECHO_END)

