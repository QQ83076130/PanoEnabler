
include ../theos/makefiles/common.mk
export ARCHS = armv7
LIBRARY_NAME = libPano
libPano_FILES = libPano.c
libPano_LDFLAGS = -lMobileGestalt
libPano_OBJCFLAGS = -I$(THEOS_PROJECT_DIR) -F$(THEOS_PROJECT_DIR)
libPano_FRAMEWORKS = CoreFoundation
## libPano_PRIVATE_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/library.mk
