TARGET =: clang
ARCHS = armv7 armv7s arm64
DEBUG = 0

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
THEOS_PACKAGE_DIR_NAME = debs
TARGET_CODESIGN_FLAGS="-Sentitlement.plist"

include $(THEOS)/makefiles/common.mk

TOOL_NAME = appinst
appinst_FILES = appinst.m $(wildcard zipzap/*.c) $(wildcard zipzap/*.cpp) $(wildcard zipzap/*.m) $(wildcard zipzap/*.mm)
appinst_CFLAGS += -std=c++11 -stdlib=libc++ -fobjc-arc -include ./zipzap/zipzap-Prefix.pch -I./zipzap -fvisibility=hidden -Wno-unused-property-ivar
appinst_FRAMEWORKS = Foundation ImageIO CoreGraphics
appinst_PRIVATE_FRAMEWORKS = MobileCoreServices
appinst_LIBRARIES = z
appinst_INSTALL_PATH = /usr/bin
include $(THEOS_MAKE_PATH)/tool.mk
