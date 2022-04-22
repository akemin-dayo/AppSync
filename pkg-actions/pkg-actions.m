#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <spawn.h>
#include <version.h>
#include <errno.h>
#include <sys/utsname.h>

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"AppSync Unified [pkg-actions] [DEBUG]: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif

#define DPKG_PATH "/var/lib/dpkg/info/net.angelxwind.appsyncunified.list"

#define L_LAUNCHDAEMON_PATH "/Library/LaunchDaemons"
#define SL_LAUNCHDAEMON_PATH "/System" L_LAUNCHDAEMON_PATH

#define INSTALLD_PLIST_PATH_L L_LAUNCHDAEMON_PATH "/com.apple.mobile.installd.plist"
#define INSTALLD_PLIST_PATH_SL SL_LAUNCHDAEMON_PATH "/com.apple.mobile.installd.plist"

#define ASU_INJECT_PLIST_PATH L_LAUNCHDAEMON_PATH "/ai.akemi.asu_inject.plist"
#define ASU_INJECT_PLIST_PATH_OLD L_LAUNCHDAEMON_PATH "/net.angelxwind.asu_inject.plist"

typedef struct __CFUserNotification *CFUserNotificationRef;
FOUNDATION_EXTERN CFUserNotificationRef CFUserNotificationCreate(CFAllocatorRef allocator, CFTimeInterval timeout, CFOptionFlags flags, SInt32 *error, CFDictionaryRef dictionary);
FOUNDATION_EXTERN SInt32 CFUserNotificationReceiveResponse(CFUserNotificationRef userNotification, CFTimeInterval timeout, CFOptionFlags *responseFlags);

static int run_posix_spawn(const char *args[]) {
	pid_t pid;
	int status;
	posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);
	waitpid(pid, &status, 0);
	return status;
}

static int run_launchctl(const char *path, const char *cmd, bool is_installd) {
	LOG("run_launchctl() %s %s\n", cmd, path);
	const char *args[] = {(access("/sbin/launchctl", X_OK) != -1) ? "/sbin/launchctl" : "/bin/launchctl", cmd, path, NULL};
	return run_posix_spawn(args);
}

int main(int argc, const char **argv) {
	#ifdef POSTINST
		LOG("Running postinst…\n");
	#else
		LOG("Running prerm…\n");
	#endif
	printf("AppSync Unified\n");
	printf("Copyright (C) 2014-2021 Karen/あけみ, Linus Yang\n");
	printf("** PLEASE DO NOT USE APPSYNC UNIFIED FOR PIRACY **\n");
	if (access(DPKG_PATH, F_OK) == -1) {
		printf("You seem to have installed AppSync Unified from an APT repository that is not cydia.akemi.ai (package ID net.angelxwind.appsyncunified).\n");
		printf("If someone other than Karen/あけみ or Linus Yang (laokongzi) is taking credit for the development of this tool, they are likely lying.\n");
		printf("Please only download AppSync Unified from the official repository to ensure file integrity and reliability.\n");
	}
	if (geteuid() != 0) {
		printf("FATAL: This binary must be run as root. …Actually, how are you even using dpkg without being root?\n");
		return 1;
	}

	if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)) {
		#ifdef POSTINST
			if (access(INSTALLD_PLIST_PATH_L, F_OK) == -1) {
				// NOTE: I thought about removing the symlinked installd plist in the prerm, but decided against it as such an operation has a non-zero chance of somehow going horribly wrong in some kind of edge case.
				printf("This device appears to be running iOS 8 or 9. Creating a symbolic link to the installd LaunchDaemon…\n");
				symlink(INSTALLD_PLIST_PATH_SL, INSTALLD_PLIST_PATH_L);
			}
		#endif
		printf("Unloading and stopping the symlinked installd LaunchDaemon…\n");
		run_launchctl(INSTALLD_PLIST_PATH_L, "unload", true);
		printf("Reloading and starting the symlinked installd LaunchDaemon…\n");
		run_launchctl(INSTALLD_PLIST_PATH_L, "load", true);
	}
	printf("Unloading and stopping the installd LaunchDaemon…\n");
	run_launchctl(INSTALLD_PLIST_PATH_SL, "unload", true);
	printf("Reloading and starting the installd LaunchDaemon…\n");
	run_launchctl(INSTALLD_PLIST_PATH_SL, "load", true);

	if (access(ASU_INJECT_PLIST_PATH_OLD, F_OK) != -1) {
		// This case should never happen, but I'm adding this check here just in case someone somehow has their system in such a weird state.
		printf("Found an old version of the asu_inject LaunchDaemon, unloading and removing it…\n");
		run_launchctl(ASU_INJECT_PLIST_PATH_OLD, "unload", false);
		unlink(ASU_INJECT_PLIST_PATH_OLD);
	}

	#ifdef __LP64__
		printf("Removing the asu_inject LaunchDaemon, as it's not required on this system.\n");
		unlink(ASU_INJECT_PLIST_PATH);
	#else
		if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_3) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)) {
			printf("This device is /probably/ running the Phœnix jailbreak (detected iOS 9.3.x and a 32-bit CPU architecture).\n");
			printf("Due to a bug in Phœnix, the asu_inject LaunchDaemon (which launches /usr/bin/asu_inject once upon boot) is required in order to properly inject AppSync Unified into installd.\n");
			if (access("/usr/bin/cynject", F_OK) != -1) {
				printf("Found cynject on this device!\n");
				chown(ASU_INJECT_PLIST_PATH, 0, 0);
				chmod(ASU_INJECT_PLIST_PATH, 0644);
				printf("Unloading and stopping the asu_inject LaunchDaemon…\n");
				run_launchctl(ASU_INJECT_PLIST_PATH, "unload", false);
				#ifdef POSTINST
					printf("Reloading and starting the asu_inject LaunchDaemon…\n");
					run_launchctl(ASU_INJECT_PLIST_PATH, "load", false);
				#endif
			} else {
				// Just in case.
				printf("Unable to find cynject on this device.\n");
				printf("Removing the asu_inject LaunchDaemon…\n");
				unlink(ASU_INJECT_PLIST_PATH);
			}
		}
	#endif

	printf("****** AppSync Unified installation complete! ******\n");

    //Janky code block to check if the device is an AppleTV. Requires <sys/utsname.h> and <errno.h>
	//Used to suppress POSTINST dialog. Replace if you have a cleaner way of doing this.
	//Perhaps you can modify this to skip the dialogue on WatchOS / BridgeOS etc. too if needed...
	struct utsname unameBuf;
   	errno = 0;
   	if (uname(&unameBuf) < 0) {
    	perror("uname");
		exit(EXIT_FAILURE);
   	}
   		//printf("Device= %s\n", unameBuf.machine);
        char *deviceNoNotification = strstr(unameBuf.machine, "AppleTV");    

	#ifdef POSTINST
		// This is flag is intended for internal use with KarenTools automated testing.
		// …That being said, nothing stops you from taking advantage of this, too. ;P
		// We also don't want to show the prompt on a device that has no way to show it properly.
		// Detect these devices and set deviceNoNotification to a value that evaluates to true.
		if ((access("/ai.akemi.appsyncunified.no-postinst-notification", F_OK) == -1) && !deviceNoNotification) {
			// TODO: For some reason, this notification doesn't appear on my iOS 10 device. It's a minor bug though, so I'll allow it for now.
			// … Even if that makes my perfectionist self scream in intense, agonising pain (🍍˃̶͈̀ロ˂̶͈́)੭ꠥ⁾⁾
			CFUserNotificationRef postinstNotification = CFUserNotificationCreate(kCFAllocatorDefault, 0, 0, NULL, (__bridge CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:
				[NSString stringWithFormat:@"%@ %@", (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) ? @"⚠️" : @"⚠", @"IMPORTANT NOTE 🍍"], @"AlertHeader",
				@"If AppSync Unified is not working after installation, please reboot your device or run ldrestart to fix it. You will only need to do this ONCE.", @"AlertMessage",
				@"Okay, I understand! (🍍•̀ω•́)୨✨", @"DefaultButtonTitle", nil]);
			CFUserNotificationReceiveResponse(postinstNotification, 0, NULL);
		}
		printf("※ IMPORTANT NOTE: If AppSync Unified is not working after installation, please reboot your device or run ldrestart to fix it. You will only need to do this ONCE.\n");
	#endif
	return 0;
}
