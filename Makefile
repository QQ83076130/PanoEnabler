include theos/makefiles/common.mk

AGGREGATE_NAME = PanoEnabler
SUBPROJECTS = Preferences Installer PanoMod actFix actHook PanoHook PanoHook7 BackBoardEnv7 RootHelper

include $(THEOS_MAKE_PATH)/aggregate.mk
