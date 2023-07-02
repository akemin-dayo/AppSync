include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppSyncUnified-installd

AppSyncUnified-installd_FILES = AppSyncUnified-installd.x dump.cpp cdhash.m
AppSyncUnified-installd_CFLAGS += -fvisibility=hidden -Wno-unused-private-field
AppSyncUnified-installd_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
