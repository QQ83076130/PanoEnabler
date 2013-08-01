
include ../theos/makefiles/common.mk
export ARCHS = armv7
TWEAK_NAME = PanoHook
PanoHook_FILES = PanoHook.mm
PanoHook_LDFLAGS = -lsubstrate
PanoHook_OBJCFLAGS = -I$(THEOS_PROJECT_DIR) -F$(THEOS_PROJECT_DIR)
PanoHook_FRAMEWORKS = CoreFoundation
PanoHook_PRIVATE_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/tweak.mk
