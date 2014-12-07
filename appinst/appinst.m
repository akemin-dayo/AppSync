/*
 *	appinst.m
 *	AppSync Unified
 *
 *	https://github.com/angelXwind/AppSync
 *	http://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified
 *
 *	Copyright (c) 2014 Linus Yang <laokongzi+appsync@gmail.com>
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
#import <objc/runtime.h>
#import <dlfcn.h>
#import "zipzap/zipzap.h"
#import "../postinst/misc.h"

#define APPNAME "appinst"
#define LOG(...) NSLog(@"" __VA_ARGS__)
#define kIdentifierKey @"CFBundleIdentifier"
#define kAppType @"User"
#define kAppTypeKey @"ApplicationType"
#define kRandomLength 6
#define APPINST_PATH "/var/lib/dpkg/info/com.linusyang.appinst.list"
#ifdef KAREN_APPINST
#define REPO "cydia.angelxwind.net"
#elif YANG_APPINST
#define REPO "yangapp.googlecode.com/svn/"
#else
#define REPO ""
#endif

static const NSString *kRandomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

#define kCopyrightKey (0x13)
#define kCopyrightLength 10
static const uint32_t kCopyrightBytes[kCopyrightLength] = {0x931b1ad2, 0xeb03394b, 0x9a83e319, 0x530bd3a3, 0xdb3999db, 0x81d1990b, 0x19113999, 0xfbd3eb32, 0x19a5393, 0xeba0989b};

typedef enum {
	AppInstExitCodeSuccess = 0x0,
	AppInstExitCodeInject,
	AppInstExitCodeZip,
	AppInstExitCodeMalformed,
	AppInstExitCodeFileSystem,
	AppInstExitCodeRuntime,
	AppInstExitCodeUnknown
} AppInstExitCode;

/* MobileInstallation for iOS 5 to 7 */
typedef void (*MobileInstallationCallback)(CFDictionaryRef information);
typedef int (*MobileInstallationInstall)(CFStringRef path, CFDictionaryRef parameters, MobileInstallationCallback callback, CFStringRef backpath);
#define MI_PATH "/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation"

/* LSApplicationWorkspace for iOS 8 */
@interface LSApplicationWorkspace : NSObject

+ (id)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;

@end

int main(int argc, const char *argv[])
{
	@autoreleasepool {
		COPY_NSLOG(kCopyrightBytes, kCopyrightLength, kCopyrightKey);
		if (access(APPINST_PATH, F_OK) == -1) {
			NSLog(@"You seem to have installed appinst from an APT repository that is not %s (package ID com.linusyang.appinst).", REPO);
			NSLog(@"If someone other than Linus Yang (laokongzi) or Karen Tsai (angelXwind) is taking credit for the development of this tool, they are likely lying.");
			NSLog(@"Remember: App Installer (appinst) is NOT for piracy. Use it legally.");
		}

#ifdef INJECT_HACK
		if (SYSTEM_GE_IOS_8()) {
			pid_t pid_installd = -1;
			int status = inject_installd(&pid_installd);
			LOG("inject installd (%d) with return %d", pid_installd, status);
		}
#endif

		/* Clean up temporary directory */
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *workPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.linusyang.appinst"];
		if ([fileManager fileExistsAtPath:workPath]) {
			if (![fileManager removeItemAtPath:workPath error:nil]) {
				LOG("failed to remove temporary path: %@, ignore", workPath);
			} else {
				LOG("clean up temporary files");
			}
		}

		/* Check arguments */
		if (argc != 2) {
			LOG("usage: " APPNAME " <ipa file>");
			return AppInstExitCodeUnknown;
		}
		
		/* Check file existence */
		NSString *filePath = [NSString stringWithUTF8String:argv[1]];
		if (![fileManager fileExistsAtPath:filePath]) {
			LOG("file %s not exist", filePath.UTF8String);
			return AppInstExitCodeFileSystem;
		}

		/* Resolve app identifier */
		NSString *appIdentifier = nil;
		ZZArchive *archive = [ZZArchive archiveWithURL:[NSURL fileURLWithPath:filePath] error:nil];
		for (ZZArchiveEntry* entry in archive.entries) {
			NSArray *componets = [[entry fileName] pathComponents];
			NSUInteger count = componets.count;
			NSString *firstComponent = componets[0];
			if ([firstComponent isEqualToString:@"/"]) {
				firstComponent = componets[1];
				count -= 1;
			}
			if (count == 3 && [firstComponent isEqualToString:@"Payload"] &&
				[componets.lastObject isEqualToString:@"Info.plist"]) {
				NSData *fileData = [entry newDataWithError:nil];
				if (fileData == nil) {
					LOG("cannot read ipa file entry");
					return AppInstExitCodeZip;
				}
				NSError *error = nil;
				NSPropertyListFormat format;
				NSDictionary * dict = (NSDictionary *) [NSPropertyListSerialization propertyListWithData:fileData
					options:NSPropertyListImmutable format:&format error:&error];
				if (dict == nil) {
					LOG("malformed Info.plist in ipa");
					return AppInstExitCodeMalformed;
				}
				appIdentifier = dict[kIdentifierKey];
				break;
			}
		}
		if (appIdentifier == nil) {
			LOG("failed to resolve app identifier");
			return AppInstExitCodeMalformed;
		}

		/* Copy file to temporary directiory */
		if (![fileManager createDirectoryAtPath:workPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			LOG("failed to create working path");
			return AppInstExitCodeFileSystem;
		}
		NSMutableString *randomString = [NSMutableString stringWithCapacity:kRandomLength];
		for (int i = 0; i < kRandomLength; i++) {
			[randomString appendFormat: @"%C", [kRandomAlphabet characterAtIndex:arc4random_uniform([kRandomAlphabet length])]];
		}
		NSString *installName = [NSString stringWithFormat:@"tmp.%@.install.ipa", randomString];
		NSString *installPath = [workPath stringByAppendingPathComponent:installName];
		if ([fileManager fileExistsAtPath:installPath]) {
			if (![fileManager removeItemAtPath:installPath error:nil]) {
				LOG("failed to remove temporary file");
				return AppInstExitCodeFileSystem;
			}
		}
		if (![fileManager copyItemAtPath:filePath toPath:installPath error:nil]) {
			LOG("failed to copy file to working path");
			return AppInstExitCodeFileSystem;
		}

		/* Call system API to install app */
		LOG(@"installing %@", appIdentifier);
		BOOL isInstalled = NO;
		if (SYSTEM_GE_IOS_8()) {
			/* Use LSApplicationWorkspace */
			Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
			if (LSApplicationWorkspace_class == nil) {
				LOG("failed to get class: LSApplicationWorkspace");
				return AppInstExitCodeRuntime;
			}
			LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
			if (workspace == nil) {
				LOG("failed to get default workspace");
				return AppInstExitCodeRuntime;
			}

			/* Install file */
			NSDictionary *options = [NSDictionary dictionaryWithObject:appIdentifier forKey:kIdentifierKey];
			@try {
				if ([workspace installApplication:[NSURL fileURLWithPath:installPath] withOptions:options]) {
					isInstalled = YES;
				}
			} @catch (NSException *e) {}
		} else {
			/* Use MobileInstallationInstall */
			void *image = dlopen(MI_PATH, RTLD_LAZY);
			if (image == NULL) {
				LOG("failed to retrieve MobileInstallation");
				return AppInstExitCodeRuntime;
			}
			MobileInstallationInstall installHandle = (MobileInstallationInstall) dlsym(image, "MobileInstallationInstall");
			if (installHandle == NULL) {
				LOG("failed to retrieve function MobileInstallationInstall");
				return AppInstExitCodeRuntime;
			}

			/* Install file */
			NSDictionary *options = [NSDictionary dictionaryWithObject:kAppType forKey:kAppTypeKey];
			if (installHandle((__bridge CFStringRef) installPath, (__bridge CFDictionaryRef) options, NULL, (__bridge CFStringRef) installPath) == 0) {
				isInstalled = YES;
			}
		}

		/* Clean up */
		if ([fileManager fileExistsAtPath:installPath] &&
			[fileManager isDeletableFileAtPath:installPath]) {
			[fileManager removeItemAtPath:installPath error:nil];
		}

		/* Exit */
		if (isInstalled) {
			LOG(@"installed %@", appIdentifier);
			return AppInstExitCodeSuccess;
		}
		LOG(@"failed to install %@", appIdentifier);
		return AppInstExitCodeUnknown;
	}
}
