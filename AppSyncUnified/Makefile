include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppSyncUnified
AppSyncUnified_FILES = AppSyncUnified.x dump.cpp
AppSyncUnified_CFLAGS += -fvisibility=hidden -Wno-unused-private-field
AppSyncUnified_LIBRARIES = substrate
include $(THEOS_MAKE_PATH)/tweak.mk
