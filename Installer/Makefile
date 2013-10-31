GO_EASY_ON_ME = 1

include ../theos/makefiles/common.mk
export ARCHS = armv7
TOOL_NAME = PanoInstaller PanoRemover

PanoInstaller_FILES = Installer.m
PanoInstaller_OBJCFLAGS = -I$(THEOS_PROJECT_DIR) -F$(THEOS_PROJECT_DIR)

PanoRemover_FILES = Remover.m
PanoRemover_OBJCFLAGS = -I$(THEOS_PROJECT_DIR) -F$(THEOS_PROJECT_DIR)

include $(THEOS_MAKE_PATH)/tool.mk

