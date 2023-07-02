#include <assert.h>
#include <dispatch/dispatch.h>
#include <mach/boolean.h>
#include <mach/mach.h>
#include <rootless.h>
#include <spawn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/types.h>

#define DPKG_PATH ROOT_PATH("/var/lib/dpkg/info/ai.akemi.appsyncunified.list")

extern char ***_NSGetEnviron(void);
extern int proc_listallpids(void *, int);
extern int proc_pidpath(int, void *, uint32_t);

static const char *cynject_path = ROOT_PATH("/usr/bin/cynject");
static const char *inject_criticald_path = ROOT_PATH("/electra/inject_criticald");
static const char *dylib_path = ROOT_PATH("/Library/MobileSubstrate/DynamicLibraries/AppSyncUnified-installd.dylib");
static const char *dispatch_queue_name = NULL;
static const char *process_name = "installd";
static int process_buffer_size = 4096;
static pid_t process_pid = -1;

static boolean_t find_process(const char *name, pid_t *ppid_ret) {
	pid_t *pid_buffer;
	char path_buffer[MAXPATHLEN];
	int count, i, ret;
	boolean_t res = FALSE;
	
	pid_buffer = (pid_t *)calloc(1, process_buffer_size);
	assert(pid_buffer != NULL);

	count = proc_listallpids(pid_buffer, process_buffer_size);
	if (count) {
		for (i = 0; i < count; i++) {
			pid_t ppid = pid_buffer[i];

			ret = proc_pidpath(ppid, (void *)path_buffer, sizeof(path_buffer));
			if (ret < 0) {
				printf("(%s:%d) proc_pidinfo() call failed.\n", __FILE__, __LINE__);
				continue;
			}

			if (strstr(path_buffer, name)) {
				res = TRUE;
				*ppid_ret = ppid;
				break;
			}
		}
	}

	free(pid_buffer);
	return res;
}

static const char *determine_suitable_injector() {
	// asu_inject should not be necessary on anything that's not 32-bit iOS 9.3.x, where cynject is pretty much guaranteed to be available.
	// That being said, I might as well add support for inject_criticald to asu_inject just for… uh, futureproofing purposes?
	// In general, asu_inject should not be necessary at all. It being required at all on any iOS version / jailbreak is merely a workaround for an old bug that will probably never be fixed.

	// ※ TODO: ElleKit appears to lack a suitable analogue to cynject.
	if (access(inject_criticald_path, X_OK) == 0) {
		return inject_criticald_path;
	}

	return cynject_path;
}

static void inject_dylib(const char *name, pid_t pid, const char *dylib) {
	char **argv;
	char pid_buf[32];
	int res;
	pid_t child;

	argv = calloc(4, sizeof(char *));
	assert(argv != NULL);

	snprintf(pid_buf, sizeof(pid_buf), "%d", pid);

	argv[0] = (char *)name;
	argv[1] = (char *)pid_buf;
	argv[2] = (char *)dylib;
	argv[3] = NULL;

	printf("(%s:%d) calling \"%s %s %s\"\n", __FILE__, __LINE__, argv[0], argv[1], argv[2]);

	res = posix_spawn(&child, argv[0], NULL, NULL, argv, (char * const *)_NSGetEnviron());
	assert(res == 0);

	return;
}

int main(int argc, char *argv[]) {
	printf("asu_inject for AppSync Unified\n");
	printf("Copyright (C) 2014-2023 Karen/あけみ\n");
	if (access(DPKG_PATH, F_OK) == -1) {
		printf("You seem to have installed AppSync Unified from an APT repository that is not cydia.akemi.ai.\n");
		printf("Please make sure that you download AppSync Unified from the official repository to ensure proper operation.\n");
	}

	if (geteuid() != 0) {
		printf("FATAL: asu_inject must be run as root.\n");
		return 1;
	}

	if ((access(cynject_path, X_OK) == -1) && (access(inject_criticald_path, X_OK) == -1)) {
		printf("FATAL: Unable to locate any suitable injectors! (%s, %s)\n", cynject_path, inject_criticald_path);
		printf("If you are certain that they exist on your filesystem, please make sure their filesystem permissions are set correctly and that they are executable.\n");
		return 1;
	}

	printf("Creating queue…\n");
	dispatch_queue_t queue = dispatch_queue_create(dispatch_queue_name, 0);

	printf("Finding installd PID…\n");
	dispatch_async(queue, ^{
		while (!find_process(process_name, &process_pid));
	});

	printf("Waiting for queue to come back…\n");
	dispatch_sync(queue, ^{});

	printf("installd's PID is %d\n", process_pid);

	printf("Injecting AppSyncUnified-installd.dylib into installd…\n");
	inject_dylib(determine_suitable_injector(), process_pid, dylib_path);
	
	return 0;
}
