#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "zipzap/zipzap.h"

#define LOG(LogContents, ...) NSLog((@"appinst: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#define kIdentifierKey @"CFBundleIdentifier"
#define kAppType @"User"
#define kAppTypeKey @"ApplicationType"
#define kRandomLength 6

#define DPKG_PATH "/var/lib/dpkg/info/com.linusyang.appinst.list"

static const NSString *kRandomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

typedef enum {
	AppInstExitCodeSuccess = 0x0,
	AppInstExitCodeInject,
	AppInstExitCodeZip,
	AppInstExitCodeMalformed,
	AppInstExitCodeFileSystem,
	AppInstExitCodeRuntime,
	AppInstExitCodeUnknown
} AppInstExitCode;

// MobileInstallation for iOS 5 to 7
typedef void (*MobileInstallationCallback)(CFDictionaryRef information);
typedef int (*MobileInstallationInstall)(CFStringRef path, CFDictionaryRef parameters, MobileInstallationCallback callback, CFStringRef backpath);
#define MI_PATH "/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation"

// LSApplicationWorkspace for iOS 8
@interface LSApplicationWorkspace : NSObject

+ (id)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;

@end

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		NSLog(@"appinst (App Installer)");
		NSLog(@"Copyright (C) 2014-2019 Linus Yang, Karen/あけみ");
		NSLog(@"** PLEASE DO NOT USE APPINST FOR PIRACY **");
		if (access(DPKG_PATH, F_OK) == -1) {
			NSLog(@"You seem to have installed appinst from a Cydia/APT repository that is not cydia.akemi.ai (package ID com.linusyang.appinst).");
			NSLog(@"If someone other than Linus Yang (laokongzi) or Karen/あけみ is taking credit for the development of this tool, they are likely lying.");
			NSLog(@"Please only download appinst from the official repository to ensure file integrity and reliability.");
		}

		// Clean up temporary directory
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *workPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.linusyang.appinst"];
		if ([fileManager fileExistsAtPath:workPath]) {
			if (![fileManager removeItemAtPath:workPath error:nil]) {
				LOG("Failed to remove temporary path: %@, ignoring.", workPath);
			} else {
				LOG("Cleaning up temporary files...");
			}
		}

		// Check arguments
		if (argc != 2) {
			LOG("Usage: appinst <path to ipa file>");
			return AppInstExitCodeUnknown;
		}
		
		// Check file existence
		NSString *filePath = [NSString stringWithUTF8String:argv[1]];
		if (![fileManager fileExistsAtPath:filePath]) {
			LOG("The file %s does not exist.", filePath.UTF8String);
			return AppInstExitCodeFileSystem;
		}

		// Resolve app identifier
		NSString *appIdentifier = nil;
		ZZArchive *archive = [ZZArchive archiveWithURL:[NSURL fileURLWithPath:filePath] error:nil];
		for (ZZArchiveEntry* entry in archive.entries) {
			NSArray *components = [[entry fileName] pathComponents];
			NSUInteger count = components.count;
			NSString *firstComponent = components[0];
			if ([firstComponent isEqualToString:@"/"]) {
				firstComponent = components[1];
				count -= 1;
			}
			if (count == 3 && [firstComponent isEqualToString:@"Payload"] &&
				[components.lastObject isEqualToString:@"Info.plist"]) {
				NSData *fileData = [entry newDataWithError:nil];
				if (fileData == nil) {
					LOG("Cannot read IPA file entry.");
					return AppInstExitCodeZip;
				}
				NSError *error = nil;
				NSPropertyListFormat format;
				NSDictionary * dict = (NSDictionary *) [NSPropertyListSerialization propertyListWithData:fileData
					options:NSPropertyListImmutable format:&format error:&error];
				if (dict == nil) {
					LOG("Malformed Info.plist in IPA.");
					return AppInstExitCodeMalformed;
				}
				appIdentifier = dict[kIdentifierKey];
				break;
			}
		}
		if (appIdentifier == nil) {
			LOG("Failed to resolve app identifier.");
			return AppInstExitCodeMalformed;
		}

		// Copy file to temporary directiory
		if (![fileManager createDirectoryAtPath:workPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			LOG("Failed to create working path.");
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
				LOG("Failed to remove temporary file.");
				return AppInstExitCodeFileSystem;
			}
		}
		if (![fileManager copyItemAtPath:filePath toPath:installPath error:nil]) {
			LOG("Failed to copy file to working path.");
			return AppInstExitCodeFileSystem;
		}

		// Call system API to install app
		LOG(@"Installing %@ ...", appIdentifier);
		BOOL isInstalled = NO;
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
			// Use LSApplicationWorkspace
			Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
			if (LSApplicationWorkspace_class == nil) {
				LOG("Failed to get class: LSApplicationWorkspace");
				return AppInstExitCodeRuntime;
			}
			LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
			if (workspace == nil) {
				LOG("Failed to get default workspace.");
				return AppInstExitCodeRuntime;
			}

			// Install file
			NSDictionary *options = [NSDictionary dictionaryWithObject:appIdentifier forKey:kIdentifierKey];
			@try {
				if ([workspace installApplication:[NSURL fileURLWithPath:installPath] withOptions:options]) {
					isInstalled = YES;
				}
			} @catch (NSException *e) {}
		} else {
			// Use MobileInstallationInstall
			void *image = dlopen(MI_PATH, RTLD_LAZY);
			if (image == NULL) {
				LOG("Failed to retrieve MobileInstallation.");
				return AppInstExitCodeRuntime;
			}
			MobileInstallationInstall installHandle = (MobileInstallationInstall) dlsym(image, "MobileInstallationInstall");
			if (installHandle == NULL) {
				LOG("Failed to retrieve function MobileInstallationInstall.");
				return AppInstExitCodeRuntime;
			}

			// Install file
			NSDictionary *options = [NSDictionary dictionaryWithObject:kAppType forKey:kAppTypeKey];
			if (installHandle((__bridge CFStringRef) installPath, (__bridge CFDictionaryRef) options, NULL, (__bridge CFStringRef) installPath) == 0) {
				isInstalled = YES;
			}
		}

		// Clean up
		if ([fileManager fileExistsAtPath:installPath] &&
			[fileManager isDeletableFileAtPath:installPath]) {
			[fileManager removeItemAtPath:installPath error:nil];
		}

		// Exit
		if (isInstalled) {
			LOG(@"Successfully installed %@", appIdentifier);
			return AppInstExitCodeSuccess;
		}
		LOG(@"Failed to install %@", appIdentifier);
		return AppInstExitCodeUnknown;
	}
}
