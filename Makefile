TARGET =: clang::5.0
ARCHS = armv7 armv7s arm64 arm64e
DEBUG = 0

THEOS_PACKAGE_DIR_NAME = debs
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += AppSyncUnified-installd
SUBPROJECTS += AppSyncUnified-FrontBoard
SUBPROJECTS += pkg-actions
SUBPROJECTS += asu_inject
include $(THEOS_MAKE_PATH)/aggregate.mk

package::
ifndef THEOS_PACKAGE_SCHEME
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsyncunified debs/nodelete-net.angelxwind.appsyncunified.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync70plus debs/nodelete-net.angelxwind.appsync70plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync60plus debs/nodelete-net.angelxwind.appsync60plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync50plus debs/nodelete-net.angelxwind.appsync50plus.deb
endif

clean::
	@rm -f debs/*.deb

after-install::
	install.exec "killall backboardd; exit 0" # backboardd doesn't exist on iOS 5, but that's fine since… FrontBoard also doesn't exist on iOS 5. ;P
