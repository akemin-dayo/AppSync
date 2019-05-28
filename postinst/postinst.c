#include <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>
#include <spawn.h>
#include <version.h>

#define DPKG_PATH "/var/lib/dpkg/info/net.angelxwind.appsyncunified.list"

#define L_LAUNCHDAEMON_PATH "/Library/LaunchDaemons"
#define SL_LAUNCHDAEMON_PATH "/System" L_LAUNCHDAEMON_PATH

#define INSTALLD_PLIST_PATH_L L_LAUNCHDAEMON_PATH "/com.apple.mobile.installd.plist"
#define INSTALLD_PLIST_PATH_SL SL_LAUNCHDAEMON_PATH "/com.apple.mobile.installd.plist"

#define ASU_INJECT_PLIST_PATH L_LAUNCHDAEMON_PATH "/net.angelxwind.asu_inject.plist"

static int run_launchctl(const char *path, const char *cmd) {
	const char *args[] = {"/bin/launchctl", cmd, path, NULL};
	pid_t pid;
	int stat;
	posix_spawn(&pid, args[0], NULL, NULL, (char **) args, NULL);
	waitpid(pid, &stat, 0);
	return stat;
}

int main(int argc, const char **argv) {
	printf("AppSync Unified\n");
	printf("Copyright (C) 2014-2019 Linus Yang, Karen/あけみ\n");
	printf("** PLEASE DO NOT USE APPSYNC UNIFIED FOR PIRACY **\n");
	if (access(DPKG_PATH, F_OK) == -1) {
		printf("You seem to have installed AppSync Unified from an APT repository that is not cydia.akemi.ai (package ID net.angelxwind.appsyncunified).\n");
		printf("If someone other than Linus Yang (laokongzi) or Karen/あけみ is taking credit for the development of this tool, they are likely lying.\n");
		printf("Please only download AppSync Unified from the official repository to ensure file integrity and reliability.\n");
	}
	if (geteuid() != 0) {
		printf("FATAL: This binary must be run as root.\n");
		return 1;
	}
	if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)) {
		#ifdef POSTINST
			if (access(INSTALLD_PLIST_PATH_L, F_OK) == -1) {
				printf("Current iOS version is iOS 8 or 9, creating symbolic link to installd plist...\n");
				symlink(INSTALLD_PLIST_PATH_SL, INSTALLD_PLIST_PATH_L);
			}
		#endif
		// NOTE: I thought about removing this symlinked plist in the prerm, but decided against it as such an operation has a non-zero chance of somehow going horribly wrong in some kind of edge case
		run_launchctl(INSTALLD_PLIST_PATH_L, "unload");
		run_launchctl(INSTALLD_PLIST_PATH_L, "load");
	} else {
		run_launchctl(INSTALLD_PLIST_PATH_SL, "unload");
		run_launchctl(INSTALLD_PLIST_PATH_SL, "load");
	}
	#ifdef __LP64__
		printf("Current device architecture is 64-bit, disabling asu_inject...\n");
		unlink(ASU_INJECT_PLIST_PATH);
	#else
		if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_3) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)) {
			printf("Current device is running 32-bit iOS 9.3.x, enabling asu_inject as a workaround for a Phoenix bug...\n");
			chown(ASU_INJECT_PLIST_PATH, 0, 0);
			chmod(ASU_INJECT_PLIST_PATH, 0644);
			run_launchctl(ASU_INJECT_PLIST_PATH, "unload");
			#ifdef POSTINST
				run_launchctl(ASU_INJECT_PLIST_PATH, "load");
			#endif
		} else {
			unlink(ASU_INJECT_PLIST_PATH);
		}
	#endif
	return 0;
}
