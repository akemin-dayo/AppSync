#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <rootless.h>
#import "zip.h"

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"[appinst] [%s] [L%d] " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif
#define kIdentifierKey @"CFBundleIdentifier"
#define kAppType @"User"
#define kAppTypeKey @"ApplicationType"
#define kRandomLength 32

#define DPKG_PATH ROOT_PATH("/var/lib/dpkg/info/ai.akemi.appinst.list")

static const NSString *kRandomAlphanumeric = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

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
		// Use NSRegularExpression to split up the Apple-provided PascalCase status string into individual words with spaces
		NSRegularExpression *pascalCaseSplitterRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])" options:0 error:nil];
		installStatus = [pascalCaseSplitterRegex stringByReplacingMatchesInString:installStatus options:0 range:NSMakeRange(0, [installStatus length]) withTemplate:@"$1 $2"];

		// Capitalise only the first character in the resulting string
		// TODO: Figure out a better/cleaner way to do this. This was simply the first method that came to my head after thinking about it for all of like, 30 seconds.
		installStatus = [NSString stringWithFormat:@"%@%@", [[installStatus substringToIndex:1] uppercaseString], [[installStatus substringWithRange:NSMakeRange(1, [installStatus length] - 1)] lowercaseString]];

		// Print status
		// Yes, I went through all this extra effort just so the user can look at some pretty strings. No, there is (probably) nothing wrong with me. ;P
		printf("%ld%% - %s…\n", (long)[percentComplete integerValue], [installStatus UTF8String]);
	}
}

// LSApplicationWorkspace for iOS 8 and above
@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options error:(NSError **)error;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;
@end

bool doesProcessAtPIDExist(pid_t pid) {
	// kill() returns 0 when the process exists, and -1 if the process does not.
	// TODO: This currently does not take into account a possible edge-case where a user can launch one instance of appinst as root, and another appinst instance as a non-privileged user.
	// In such a case, if the non-privileged appinst attempts to kill(), it would return -1 due to failing the permission check, therefore resulting in a false positive.
	return (kill(pid, 0) == 0);
}

bool isSafeToDeleteAppInstTemporaryDirectory(NSString *workPath) {
	// There is no point in running multiple instances of appinst, as app installation on iOS can only happen one app at a time.
	// … That being said, some people may still try to do so anyway — iOS /does/ gracefully handle such a state, and will simply wait for an existing install session lock to release before proceeding.
	// However, appinst's temporary directory self-cleanup code prior to appinst 1.2 could potentially result in a slight issue if the user tries to run multiple appinst instances.
	// If you launch two appinst instances in quick enough succession, both will fail to install due to their temporary IPA copies having been deleted by each other.
	// ※ If you don't do it quickly, then nothing will really happen, because the file handle would have already been opened by MobileInstallation / LSApplicationWorkSpace, and the deletion wouldn't really take effect until the file handle was closed.
	// But in the interest of making appinst as robust as I possibly can, here's some code to handle this potential edge-case.

	// Build a list of all PID files in the temporary directory
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workPath error:nil];
	NSArray *pidFiles = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.pid'"]];
	for (NSString *pidFile in pidFiles) {
		// Read the PID file contents and assign it to a pid_t
		NSString *pidFilePath = [workPath stringByAppendingPathComponent:pidFile];
		pid_t pidToCheck = [[NSString stringWithContentsOfFile:pidFilePath encoding:NSUTF8StringEncoding error:nil] intValue];
		if (pidToCheck == 0) {
			// If the resulting pid_t ends up as 0, something went horribly wrong while parsing the contents of the PID file.
			// We'll just treat this failed state as if there are other active instances of appinst, just in case.
			printf("Failed to read the PID from %s! Proceeding as if there are other active instances of appinst…", [pidFilePath UTF8String]);
			return false;
		}
		if (doesProcessAtPIDExist(pidToCheck)) {
			// If the PID exists, this means that there is another appinst instance in an active install session.
			// This also takes into account PID files left over by an appinst that crashed or was otherwise interrupted, and therefore didn't get to clean up after itself
			printf("Another instance of appinst seems to be in an active install session. Proceeding without deleting the temporary directory…\n");
			return false;
		}
	}
	return true;
}

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		printf("appinst (App Installer)\n");
		printf("Copyright (C) 2014-2023 Karen/あけみ\n");
		printf("** PLEASE DO NOT USE APPINST FOR PIRACY **\n");
		if (access(DPKG_PATH, F_OK) == -1) {
			printf("You seem to have installed appinst from an APT repository that is not cydia.akemi.ai.\n");
			printf("Please make sure that you download AppSync Unified from the official repository to ensure proper operation.\n");
		}

		if (access(ROOT_PATH("/.installed_dopamine"), F_OK) == 0) {
			printf("WARNING: You appear to be using the Dopamine jailbreak.\n");
			printf("There is a known IPC (inter-process communication) issue with Dopamine that may prevent apps from successfully installing.\n");
			printf("It may also cause the TrollStore app to become temporarily unusable.\n");
			printf("To restore TrollStore functionality, open your persistence helper (such as \"GTA Car Tracker\") and select \"Refresh App Registrations\".\n");
		}

		// Construct our temporary directory path
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *workPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"appinst"];

		// If there was a leftover temporary directory from a previous run, clean it up
		if ([fileManager fileExistsAtPath:workPath] && isSafeToDeleteAppInstTemporaryDirectory(workPath)) {
			if (![fileManager removeItemAtPath:workPath error:nil]) {
				// This theoretically should never happen, now that appinst sets 0777 directory permissions for its temporary directory as of version 1.2.
				// That, and the temporary directory is also different as of 1.2, too, so even if an older version of appinst was run as root, it should not affect appinst 1.2.
				printf("Failed to delete leftover temporary directory at %s, continuing anyway.\n", [workPath UTF8String]);
				printf("This can happen if the previous temporary directory was created by the root user.\n");
			} else {
				printf("Deleting leftover temporary directory…\n");
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
				NSError *error;
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

		// Generate a random string which will be used as a reasonably unique session ID
		NSMutableString *sessionID = [NSMutableString stringWithCapacity:kRandomLength];
		for (int i = 0; i < kRandomLength; i++) {
			[sessionID appendFormat: @"%C", [kRandomAlphanumeric characterAtIndex:arc4random_uniform([kRandomAlphanumeric length])]];
		}

		// Write the current appinst PID to a file corresponding to the session ID
		// This is only used in isSafeToDeleteAppInstTemporaryDirectory() — see the comments in that function for more information.
		pid_t currentPID = getpid();
		printf("Initialising appinst installation session ID %s (PID %d)…\n", [sessionID UTF8String], currentPID);
		NSString *pidFilePath = [workPath stringByAppendingPathComponent:[NSString stringWithFormat:@"appinst-session-%@.pid", sessionID]];
		if (![[NSString stringWithFormat:@"%d", currentPID] writeToFile:pidFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
			// If we fail to write the PID, just ignore it and continue on. It's very unlikely that users will even run into the rare issue that this code is a fix for, anyway.
			printf("Failed to write PID file to %s, continuing anyway.\n", [pidFilePath UTF8String]);
		}

		// Copy the user-specified IPA to the temporary directory
		// The reason why we do this is because MobileInstallation / LSApplicationWorkSpace will actually delete the IPA once it's finished extracting.
		NSString *installName = [NSString stringWithFormat:@"appinst-session-%@.ipa", sessionID];
		NSString *installPath = [workPath stringByAppendingPathComponent:installName];
		if ([fileManager fileExistsAtPath:installPath]) {
			// It is extremely unlikely (almost impossible) for a session ID collision to occur, but if it does, we'll delete the conflicting IPA.
			if (![fileManager removeItemAtPath:installPath error:nil]) {
				// … It's also possible (but even /more/ unlikely) that this will fail.
				// If this somehow happens, just instruct the user to try again. That will give them a different, non-conflicting session ID.
				printf("Failed to delete conflicting leftover temporary files from a previous appinst session at %s. Please try running appinst again.\n", [installPath UTF8String]);
				return AppInstExitCodeFileSystem;
			}
		}
		if (![fileManager copyItemAtPath:filePath toPath:installPath error:nil]) {
			printf("Failed to copy the specified IPA to the temporary directory. Do you have enough free disk space?\n");
			return AppInstExitCodeFileSystem;
		}

		// Call system APIs to actually install the app
		printf("Installing \"%s\"…\n", [appIdentifier UTF8String]);
		BOOL isInstalled = false;
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
			NSError *error;
			@try {
				if ([workspace installApplication:[NSURL fileURLWithPath:installPath] withOptions:options error:&error]) {
					isInstalled = YES;
				}
			} @catch (NSException *exception) {
				printf("An exception occurred while attempting to install the app!\n");
				printf("NSException info: %s\n", [[NSString stringWithFormat:@"%@", exception] UTF8String]);
			}
			if (error) {
				printf("An error occurred while attempting to install the app!\n");
				printf("NSError info: %s\n", [[NSString stringWithFormat:@"%@", error] UTF8String]);
			}
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

		// Clean up appinst PID file for current session ID
		if ([fileManager fileExistsAtPath:pidFilePath] && [fileManager isDeletableFileAtPath:pidFilePath]) {
			printf("Cleaning up appinst session ID %s (PID %d)…\n", [sessionID UTF8String], currentPID);
			[fileManager removeItemAtPath:pidFilePath error:nil];
		}

		// Clean up temporary copied IPA
		if ([fileManager fileExistsAtPath:installPath] && [fileManager isDeletableFileAtPath:installPath]) {
			printf("Cleaning up temporary files…\n");
			[fileManager removeItemAtPath:installPath error:nil];
		}

		// Clean up temporary directory
		if ([fileManager fileExistsAtPath:workPath] && [fileManager isDeletableFileAtPath:workPath] && isSafeToDeleteAppInstTemporaryDirectory(workPath)) {
			printf("Deleting temporary directory…\n");
			[fileManager removeItemAtPath:workPath error:nil];
		}

		// Print final results
		if (isInstalled) {
			printf("Successfully installed \"%s\"!\n", [appIdentifier UTF8String]);
			return AppInstExitCodeSuccess;
		}
		printf("Failed to install \"%s\".\n", [appIdentifier UTF8String]);
		return AppInstExitCodeUnknown;
	}
}
