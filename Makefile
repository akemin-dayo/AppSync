include theos/makefiles/common.mk

export ARCHS = armv7 arm64
VERBOSE = 1

TWEAK_NAME = AppSync
AppSync_FILES = Tweak.xm
AppSync_LDFLAGS = -lsubstrate

include $(THEOS_MAKE_PATH)/tweak.mk
