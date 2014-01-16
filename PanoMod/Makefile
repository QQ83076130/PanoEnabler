GO_EASY_ON_ME = 1

TARGET := iphone:clang
SDKVERSION_armv7 = 6.0
SDKVERSION_armv64 = 7.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION := 6.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 := 7.0
ARCHS := armv7 armv7s arm64

TWEAK_NAME = actHack
actHack_FILES = actHack.xm
actHack_FRAMEWORKS = AVFoundation UIKit

include ../theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
