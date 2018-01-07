TARGET =: clang
ARCHS = armv7 armv7s arm64
DEBUG = 0

checkerrors::
	ifeq ($(shell test -d $(THEOS)/makefiles/ && echo -n yes),yes)   
		include $(THEOS)/makefiles/common.mk
		include $(THEOS_MAKE_PATH)/aggregate.mk
	else
	    $(error THEOS is not installed or configured properly.)
	endif

THEOS_PACKAGE_DIR_NAME = debs
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)


SUBPROJECTS += AppSyncUnified
SUBPROJECTS += postinst
SUBPROJECTS += asu_inject

package::
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync70plus debs/net.angelxwind.appsync70plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync60plus debs/net.angelxwind.appsync60plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync50plus debs/net.angelxwind.appsync50plus.deb

clean::
	@rm -f debs/*.deb
