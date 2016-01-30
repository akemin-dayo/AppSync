/*
 *	AppSyncUnified.x
 *	AppSync Unified
 *
 *	https://github.com/angelXwind/AppSync
 *	http://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified
 *
 *	Copyright (c) 2014 Linus Yang <laokongzi+appsync@gmail.com>, Karen Tsai <angelXwind@angelxwind.net>
 *
 *	AppSync Unified is NOT for piracy. Use it legally.
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "../postinst/misc.h"
#import "dump.h"

/* Minimal Cydia Substrate header */
typedef const void *MSImageRef;
MSImageRef MSGetImageByName(const char *file);
void *MSFindSymbol(MSImageRef image, const char *name);
void MSHookFunction(void *symbol, void *replace, void **result);

#define KAREN_ASU_PATH "/var/lib/dpkg/info/net.angelxwind.appsyncunified.list"
#define YANG_ASU_PATH "/var/lib/dpkg/info/com.linusyang.appsync.list"

#ifdef DEBUG
#define LOG(...) NSLog(@"AppSync Unified: " __VA_ARGS__)
#else
#define LOG(...)
#endif

#define DECL_FUNC(name, ret, ...) \
	static ret (*original_ ## name)(__VA_ARGS__); \
	ret custom_ ## name(__VA_ARGS__)
#define HOOK_FUNC(name, image) do { \
	void *_ ## name = MSFindSymbol(image, "_" #name); \
	if (_ ## name == NULL) { \
		LOG(@"Failed to load symbol: " #name "."); \
		return; \
	} \
	MSHookFunction(_ ## name, (void *) custom_ ## name, (void **) &original_ ## name); \
} while(0)
#define LOAD_IMAGE(image, path) do { \
	image = MSGetImageByName(path); \
	if (image == NULL) { \
		LOG(@"Failed to load " #image "."); \
		return; \
	} \
} while (0)

#define kSecMagicBytesLength 2
static const uint8_t kSecMagicBytes[kSecMagicBytesLength] = {0xa1, 0x13};
#define kSecSubjectCStr "Apple iPhone OS Application Signing"

static void copyIdentifierAndEntitlements(NSString *path, NSString **identifier, NSDictionary **info)
{
	if (path == nil || identifier == NULL || info == NULL) {
		LOG(@"copyIdentifierAndEntitlements: null args");
		return;
	}

	LOG(@"bundle path: %@", path);
	NSBundle *bundle = [NSBundle bundleWithPath:path];

	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if (bundleIdentifier != nil) {
		*identifier = [[NSString alloc] initWithString:bundleIdentifier];
		LOG(@"bundle id: %@", bundleIdentifier);
	}

	NSString *executablePath = [bundle executablePath];
	NSArray *paths = [executablePath pathComponents];
	if (paths.count > 0 && [paths.lastObject isEqualToString:@"Cydia"]) {
		NSMutableArray *newPaths = [NSMutableArray arrayWithArray:paths];
		newPaths[newPaths.count - 1] = @"MobileCydia";
		executablePath = [NSString pathWithComponents:newPaths];
	}
	LOG(@"bundle exec: %@", executablePath);

	NSMutableData *data = [NSMutableData data];
	int ret = copyEntitlementDataFromFile(executablePath.UTF8String, (CFMutableDataRef) data);
	if (ret == kCopyEntSuccess) {
		NSError *error;
		NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
		NSMutableDictionary *mutableInfo = [[NSMutableDictionary alloc] initWithDictionary:plist];
		if ([mutableInfo objectForKey:@"application-identifier"] == nil) {
			if ([mutableInfo objectForKey:@"com.apple.developer.team-identifier"] != nil) {
				[mutableInfo setObject:[NSString stringWithFormat:@"%@.%@", [mutableInfo objectForKey:@"com.apple.developer.team-identifier"], bundleIdentifier] forKey:@"application-identifier"];
			} else {
				[mutableInfo setObject:bundleIdentifier forKey:@"application-identifier"];
			}
		}
		*info = [mutableInfo copy];
	} else {
		LOG(@"failed to fetch entitlements: %@", (NSString *) entErrorString(ret));
	}
}

DECL_FUNC(SecCertificateCreateWithData, SecCertificateRef, CFAllocatorRef allocator, CFDataRef data)
{
	SecCertificateRef result = original_SecCertificateCreateWithData(allocator, data);
	if (result == NULL) {
		CFDataRef dataRef = CFDataCreate(NULL, kSecMagicBytes, kSecMagicBytesLength);
		if (data != NULL && CFEqual(dataRef, data)) {
			result = (SecCertificateRef) dataRef;
		} else {
			CFRelease(dataRef);
		}
	}
	return result;
}

DECL_FUNC(SecCertificateCopySubjectSummary, CFStringRef, SecCertificateRef certificate)
{
	if (CFGetTypeID(certificate) == CFDataGetTypeID()) {
		return CFStringCreateWithCString(NULL, kSecSubjectCStr, kCFStringEncodingUTF8);
	}
	CFStringRef result = original_SecCertificateCopySubjectSummary(certificate);
	return result;
}

DECL_FUNC(MISValidateSignatureAndCopyInfo, uintptr_t, NSString *path, uintptr_t b, NSDictionary **info)
{
#ifdef KAREN_ASU
	if (access(KAREN_ASU_PATH, F_OK) == -1) {
		NSLog(@"You seem to have installed AppSync Unified from an APT repository that is not cydia.angelxwind.net (package ID net.angelxwind.appsyncunified).");
		NSLog(@"If someone other than Linus Yang (laokongzi) or Karen Tsai (angelXwind) is taking credit for the development of this tweak, they are likely lying.");
		NSLog(@"Remember: AppSync Unified is NOT for piracy. Use it legally.");
	}
#endif
#ifdef YANG_ASU
	if (access(YANG_ASU_PATH, F_OK) == -1) {
		NSLog(@"You seem to have installed AppSync from an APT repository that is not yangapp.googlecode.com/svn/ (package ID com.linusyang.appsync).");
		NSLog(@"If someone other than Linus Yang (laokongzi) or Karen Tsai (angelXwind) is taking credit for the development of this tweak, they are likely lying.");
		NSLog(@"Remember: AppSync is NOT for piracy. Use it legally.");
	}
#endif
	original_MISValidateSignatureAndCopyInfo(path, b, info);
	if (info == NULL) {
		LOG(@"Boo, NULL info");
	} else if (*info == nil) {
		LOG(@"Ahh, nil info, fake it");
		if (SYSTEM_GE_IOS_8()) {
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				MSImageRef imageSec;
				LOAD_IMAGE(imageSec, "/System/Library/Frameworks/Security.framework/Security");
				HOOK_FUNC(SecCertificateCreateWithData, imageSec);
				HOOK_FUNC(SecCertificateCopySubjectSummary, imageSec);
				LOG(@"Security.framework injected");
			});

			NSMutableDictionary *fakeInfo = [[NSMutableDictionary alloc] init];
			NSDictionary *entitlements = nil;
			NSString *identifier = nil;
			copyIdentifierAndEntitlements(path, &identifier, &entitlements);
			if (entitlements != nil) {
				[fakeInfo setObject:entitlements forKey:@"Entitlements"];
				[entitlements release];
			}
			if (identifier != nil) {
				[fakeInfo setObject:identifier forKey:@"SigningID"];
				[identifier release];
			}
			[fakeInfo setObject:[NSData dataWithBytes:kSecMagicBytes length:kSecMagicBytesLength] forKey:@"SignerCertificate"];
			[fakeInfo setObject:[NSDate date] forKey:@"SigningTime"];
			[fakeInfo setObject:[NSNumber numberWithBool:NO] forKey:@"ValidatedByProfile"];
			LOG(@"faked info: %@", fakeInfo);
			*info = fakeInfo;
		}
	} else {
		LOG(@"Hooray, info is okay");
		LOG(@"orig info: %@", *info);
	}
	return 0;
}

%ctor {
	@autoreleasepool {
		MSImageRef image;
		LOAD_IMAGE(image, "/usr/lib/libmis.dylib");
		HOOK_FUNC(MISValidateSignatureAndCopyInfo, image);
		LOG(@"libmis.dylib injected");
	}
}
