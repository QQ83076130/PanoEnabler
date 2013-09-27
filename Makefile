include theos/makefiles/common.mk
export SDKVERSION = 6.0

AGGREGATE_NAME = PanoEnabler
SUBPROJECTS = Preferences Installer PanoMod actHook PanoHook

include $(THEOS_MAKE_PATH)/aggregate.mk
