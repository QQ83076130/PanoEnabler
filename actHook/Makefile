include ../theos/makefiles/common.mk

SDKVERSION_armv7 = 6.0
SDKVERSION_armv64 = 7.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 6.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ARCHS = armv7 armv7s arm64

TWEAK_NAME = actHook
actHook_FILES = actHook.xm
actHook_LIBRARIES = substrate
actHook_PRIVATE_FRAMEWORKS = ACTFramework

include $(THEOS_MAKE_PATH)/tweak.mk
