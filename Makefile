include theos/makefiles/common.mk

AGGREGATE_NAME = PanoEnabler
SUBPROJECTS = Preferences Installer PanoMod actHook PanoHook

include $(THEOS_MAKE_PATH)/aggregate.mk
