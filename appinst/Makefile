export TARGET = iphone:clang:latest:5.0
export ARCHS = armv7 armv7s arm64
export DEBUG = 0

# This is already defined by KarenTools/AkemiTools internally, but I'm defining it here in the public Makefile as well, just to make the lives of any potential contributors easier.
# ※ Note: You will have to manually run `make clean` twice — once for each packaging scheme and corresponding data directory.
ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
	export _THEOS_RELATIVE_DATA_DIR = ".theos-rootless"
endif

THEOS_PACKAGE_DIR_NAME = debs
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

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
ifndef THEOS_PACKAGE_SCHEME
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip "transitional/nodelete-com.linusyang.appinst" "$(THEOS_PACKAGE_DIR_NAME)/nodelete-com.linusyang.appinst.deb"
endif
