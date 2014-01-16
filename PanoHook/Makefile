TARGET := iphone:clang
SDKVERSION_armv7 = 6.0
SDKVERSION_armv64 = 7.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION := 6.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 := 7.0
ARCHS := armv7 armv7s arm64

TWEAK_NAME = PanoHook
PanoHook_FILES = PanoHook.xm
PanoHook_LIBRARIES = substrate MobileGestalt
PanoHook_FRAMEWORKS = CoreFoundation IOKit
PanoHook_PRIVATE_FRAMEWORKS = ACTFramework

include ../theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
