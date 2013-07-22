include theos/makefiles/common.mk

AGGREGATE_NAME = PanoEnabler
SUBPROJECTS = Preferences Installer BackBoardEnv PanoMod libPano actHook

include $(THEOS_MAKE_PATH)/aggregate.mk
