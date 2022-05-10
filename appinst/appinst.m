#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "zip.h"

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"appinst [DEBUG]: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif
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

// MobileInstallation for iOS 5〜7
typedef void (*MobileInstallationCallback)(CFDictionaryRef information);
typedef int (*MobileInstallationInstall)(CFStringRef path, CFDictionaryRef parameters, MobileInstallationCallback callback, CFStringRef backpath);
#define MI_PATH "/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation"

void mobileInstallationStatusCallback(CFDictionaryRef information) {
	NSDictionary *installInfo = (__bridge NSDictionary *)information;
	NSNumber *percentComplete = [installInfo objectForKey:@"PercentComplete"];
	NSString *installStatus = [installInfo objectForKey:@"Status"];

	if (installStatus) {
		// Use NSRegularExpression to split up the PascalCase status string into individual words with spaces
		NSRegularExpression *pascalCaseSplitterRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])" options:0 error:nil];
		installStatus = [pascalCaseSplitterRegex stringByReplacingMatchesInString:installStatus options:0 range:NSMakeRange(0, [installStatus length]) withTemplate:@"$1 $2"];

		// Capitalise only the first character in the resulting string
		// TODO: Figure out a better/cleaner way to do this.
		installStatus = [NSString stringWithFormat:@"%@%@", [[installStatus substringToIndex:1] uppercaseString], [[installStatus substringWithRange:NSMakeRange(1, [installStatus length] - 1)] lowercaseString]];

		// Print status
		printf("%ld%% - %s…\n", (long)[percentComplete integerValue], [installStatus UTF8String]);
	}
}

// LSApplicationWorkspace for iOS 8 and above
@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;
@end

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		printf("appinst (App Installer)\n");
		printf("Copyright (C) 2014-2022 Karen/あけみ\n");
		printf("** PLEASE DO NOT USE APPINST FOR PIRACY **\n");
		if (access(DPKG_PATH, F_OK) == -1) {
			printf("You seem to have installed appinst from an APT repository that is not cydia.akemi.ai.\n");
			printf("Please make sure that you download AppSync Unified from the official repository to ensure proper operation.\n");
		}

		// Construct our temporary directory path
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *workPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"appinst"];

		// If there was a leftover temporary directory from a previous run, clean it up
		if ([fileManager fileExistsAtPath:workPath]) {
			if (![fileManager removeItemAtPath:workPath error:nil]) {
				// This theoretically should never happen, now that appinst sets 0777 directory permissions for its temporary directory as of version 1.2.
				// That, and the temporary directory is also different as of 1.2, too, so even if an older version of appinst was run as root, it should not affect appinst 1.2.
				printf("Failed to remove leftover temporary directory: %s, ignoring.\n", [workPath UTF8String]);
				printf("This can happen if the previous temporary directory was created by the root user.\n");
			} else {
				printf("Found a leftover temporary directory! Cleaning it up…\n");
			}
		}

		// Print usage information if the number of arguments was incorrect
		if (argc != 2) {
			printf("Usage: appinst <path to IPA file>\n");
			return AppInstExitCodeUnknown;
		}
		
		// Check if the user-specified file path exists
		NSString *filePath = [NSString stringWithUTF8String:argv[1]];
		if (![fileManager fileExistsAtPath:filePath]) {
			// If the first argument is -h or --help, print usage information
			if ([filePath isEqualToString:@"-h"] || [filePath isEqualToString:@"--help"]) {
				printf("Usage: appinst <path to IPA file>\n");
				return AppInstExitCodeUnknown;
			}
			printf("The file \"%s\" could not be found. Perhaps you made a typo?\n", [filePath UTF8String]);
			return AppInstExitCodeFileSystem;
		}

		// Resolve app identifier
		NSString *appIdentifier = nil;
		int err = 0;
		zip_t *archive = zip_open(argv[1], 0, &err);
		if (err) {
			printf("Unable to read the specified IPA file.\n");
			return AppInstExitCodeZip;
		}
		zip_int64_t num_entries = zip_get_num_entries(archive, 0);
		for (zip_uint64_t i = 0; i < num_entries; ++i) {
			const char* name = zip_get_name(archive, i, 0);
			if (!name) {
				printf("Unable to read the specified IPA file.\n");
				zip_close(archive);
				return AppInstExitCodeZip;
			}
			NSString *fileName = [NSString stringWithUTF8String:name];
			NSArray *components = [fileName pathComponents];
			NSUInteger count = components.count;
			NSString *firstComponent = [components objectAtIndex:0];
			if ([firstComponent isEqualToString:@"/"]) {
				firstComponent = [components objectAtIndex:1];
				count -= 1;
			}
			if (count == 3 && [firstComponent isEqualToString:@"Payload"] &&
				[components.lastObject isEqualToString:@"Info.plist"]) {
				zip_stat_t st;
				zip_stat_init(&st);
				zip_stat_index(archive, i, 0, &st);

				void *buffer = malloc(st.size);
				if (!buffer) {
					printf("Unable to read the specified IPA file.\n");
					zip_close(archive);
					return AppInstExitCodeZip;
				}

				zip_file_t *file_in_zip = zip_fopen_index(archive, i, 0);
				if (!file_in_zip) {
					printf("Unable to read the specified IPA file.\n");
					zip_close(archive);
					return AppInstExitCodeZip;
				}

				zip_fread(file_in_zip, buffer, st.size);
				zip_fclose(file_in_zip);

				NSData *fileData = [NSData dataWithBytesNoCopy:buffer length:st.size freeWhenDone:YES];
				if (fileData == nil) {
					printf("Unable to read the specified IPA file.\n");
					return AppInstExitCodeZip;
				}
				NSError *error = nil;
				NSPropertyListFormat format;
				NSDictionary * dict = (NSDictionary *) [NSPropertyListSerialization propertyListWithData:fileData
					options:NSPropertyListImmutable format:&format error:&error];
				if (dict == nil) {
					printf("The specified IPA file contains a malformed Info.plist.\n");
					return AppInstExitCodeMalformed;
				}
				appIdentifier = [dict objectForKey:kIdentifierKey];
				break;
			}
		}

		zip_close(archive);

		if (appIdentifier == nil) {
			printf("Failed to resolve app identifier for the specified IPA file.\n");
			return AppInstExitCodeMalformed;
		}

		// Begin copying the IPA to a temporary directory
		// First, we need to set the permissions of the temporary directory itself to 0777, to avoid running into permission issues if the user runs appinst as root.
		NSDictionary *workPathDirectoryPermissions = [NSDictionary dictionaryWithObject:@0777 forKey:NSFilePosixPermissions];
		if (![fileManager createDirectoryAtPath:workPath withIntermediateDirectories:YES attributes:workPathDirectoryPermissions error:nil]) {
			printf("Failed to create temporary directory.\n");
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
				// Defensive error handling for a case that can… theoretically occur.
				printf("Failed to remove leftover temporary files.\n");
				return AppInstExitCodeFileSystem;
			}
		}
		if (![fileManager copyItemAtPath:filePath toPath:installPath error:nil]) {
			printf("Failed to copy the specified IPA to the temporary directory.\n");
			return AppInstExitCodeFileSystem;
		}

		// Call system APIs to actually install the app
		printf("Installing \"%s\"…\n", [appIdentifier UTF8String]);
		BOOL isInstalled = NO;
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
			// Use LSApplicationWorkspace on iOS 8 and above
			Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
			if (LSApplicationWorkspace_class == nil) {
				printf("Failed to get class: LSApplicationWorkspace\n");
				return AppInstExitCodeRuntime;
			}

			LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
			if (workspace == nil) {
				printf("Failed to get the default workspace.\n");
				return AppInstExitCodeRuntime;
			}

			// Install app
			NSDictionary *options = [NSDictionary dictionaryWithObject:appIdentifier forKey:kIdentifierKey];
			@try {
				if ([workspace installApplication:[NSURL fileURLWithPath:installPath] withOptions:options]) {
					isInstalled = YES;
				}
			} @catch (NSException *e) {}
		} else {
			// Use MobileInstallationInstall on iOS 5〜7
			void *image = dlopen(MI_PATH, RTLD_LAZY);
			if (image == NULL) {
				printf("Failed to retrieve MobileInstallation.\n");
				return AppInstExitCodeRuntime;
			}

			MobileInstallationInstall installHandle = (MobileInstallationInstall) dlsym(image, "MobileInstallationInstall");
			if (installHandle == NULL) {
				printf("Failed to retrieve the MobileInstallationInstall function.\n");
				return AppInstExitCodeRuntime;
			}

			// Install app
			NSDictionary *options = [NSDictionary dictionaryWithObject:kAppType forKey:kAppTypeKey];
			if (installHandle((__bridge CFStringRef) installPath, (__bridge CFDictionaryRef) options, &mobileInstallationStatusCallback, (__bridge CFStringRef) installPath) == 0) {
				isInstalled = YES;
			}
		}

		// Clean up temporary copied IPA
		if ([fileManager fileExistsAtPath:installPath] && [fileManager isDeletableFileAtPath:installPath]) {
			printf("Removing temporary files…\n");
			[fileManager removeItemAtPath:installPath error:nil];
		}

		// Clean up temporary directory
		if ([fileManager fileExistsAtPath:workPath] && [fileManager isDeletableFileAtPath:workPath]) {
			printf("Removing temporary directory…\n");
			[fileManager removeItemAtPath:workPath error:nil];
		}

		// Print results
		if (isInstalled) {
			printf("Successfully installed \"%s\"!\n", [appIdentifier UTF8String]);
			return AppInstExitCodeSuccess;
		}

		printf("Failed to install \"%s\".\n", [appIdentifier UTF8String]);
		return AppInstExitCodeUnknown;
	}
}
