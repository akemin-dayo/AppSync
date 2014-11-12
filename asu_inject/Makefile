IPHONE_ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0
DEBUG = 0
include $(THEOS)/makefiles/common.mk
TOOL_NAME = asu_inject
asu_inject_FILES = asu_inject.c
asu_inject_CFLAGS += -fvisibility=hidden
asu_inject_INSTALL_PATH = /usr/bin
include $(THEOS_MAKE_PATH)/tool.mk
