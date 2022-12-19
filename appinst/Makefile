TARGET =: clang::5.0
ARCHS = armv7 armv7s arm64
DEBUG = 0

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
THEOS_PACKAGE_DIR_NAME = debs

include $(THEOS)/makefiles/common.mk

TOOL_NAME = appinst
appinst_FILES = appinst.m
appinst_CCFLAGS += -std=c++11 -stdlib=libc++ -fobjc-arc -include ./zip.h -I . -fvisibility=hidden -Wno-unused-property-ivar
appinst_CFLAGS += -fobjc-arc -include ./zip.h -I . -fvisibility=hidden -Wno-unused-property-ivar
appinst_FRAMEWORKS = Foundation ImageIO CoreGraphics
appinst_PRIVATE_FRAMEWORKS = MobileCoreServices
appinst_LDFLAGS += $(THEOS)/lib/libzip.a
appinst_LIBRARIES = z
appinst_INSTALL_PATH = /usr/bin
appinst_CODESIGN_FLAGS = -Sappinst_entitlements.plist
include $(THEOS_MAKE_PATH)/tool.mk

package::
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-com.linusyang.appinst debs/nodelete-com.linusyang.appinst.deb
