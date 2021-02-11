#ifdef __cplusplus
extern "C" {
#endif

#include <CoreFoundation/CoreFoundation.h>

int copyEntitlementDataFromFile(const char *path, CFMutableDataRef output);

enum {
	kCopyEntSuccess = 0,
	kCopyEntArgumentNull = 1,
	kCopyEntMapFail = 2,
	kCopyEntMachO = 3,
	kCopyEntUnknown = 4
};

#ifdef DEBUG
#include <CoreFoundation/CFLogUtilities.h>
CFStringRef entErrorString(int code);
#endif

#ifdef __cplusplus
}
#endif
