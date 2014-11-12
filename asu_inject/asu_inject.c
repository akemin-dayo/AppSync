/*
 *    asu_inject.c
 *    AppSync Unified
 *
 *    https://github.com/angelXwind/AppSync
 *    http://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified
 *
 *    Copyright (c) 2014 Karen Tsai <angelXwind@angelxwind.net>
 *
 *    AppSync Unified is NOT for piracy. Use it legally.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sys/cdefs.h>
#include <sys/types.h>
#include <sys/param.h>
#include <mach/mach.h>
#include <mach/boolean.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <assert.h>

extern char*** _NSGetEnviron(void);
extern int proc_listallpids(void*, int);
extern int proc_pidpath(int, void*, uint32_t);

static const char* cynject_path = "/usr/bin/cynject";
static const char* dylib_path = "/Library/MobileSubstrate/DynamicLibraries/AppSyncUnified.dylib";
static const char* dispatch_queue_name = NULL;
static const char* process_name = "installd";
static int process_buffer_size = 4096;
static pid_t process_pid = -1;

static boolean_t find_process(const char* name, pid_t* ppid_ret) {
	pid_t *pid_buffer;
	char path_buffer[MAXPATHLEN];
	int count, i, ret;
	boolean_t res = FALSE;
	
	pid_buffer = (pid_t*)calloc(1, process_buffer_size);
	assert(pid_buffer != NULL);

	count = proc_listallpids(pid_buffer, process_buffer_size);
	if(count) {
		for(i = 0; i < count; i++) {
			pid_t ppid = pid_buffer[i];

			ret = proc_pidpath(ppid, (void*)path_buffer, sizeof(path_buffer));
			if(ret < 0) {
				printf("(%s:%d) proc_pidinfo() call failed.\n", __FILE__, __LINE__);
				continue;
			}

			if(strstr(path_buffer, name)) {
				res = TRUE;
				*ppid_ret = ppid;
				break;
			}
		}
	}

	free(pid_buffer);
	return res;
}

static void inject_dylib(const char* name, pid_t pid, const char* dylib) {
	char** argv;
	char pid_buf[32];
	int res;
	pid_t child;

	argv = calloc(4, sizeof(char*));
	assert(argv != NULL);

	snprintf(pid_buf, sizeof(pid_buf), "%d", pid);

	argv[0] = (char*)name;
	argv[1] = (char*)pid_buf;
	argv[2] = (char*)dylib;
	argv[3] = NULL;

	printf("(%s:%d) calling \"%s %s %s\"\n", __FILE__, __LINE__, argv[0], argv[1], argv[2]);

	res = posix_spawn(&child, argv[0], NULL, NULL, argv, (char* const*)_NSGetEnviron());
	assert(res == 0);

	return;
}

int main(int argc, char* argv[]) {
	printf("asu_inject for AppSync Unified 5\n");
	printf("For use on iOS installations with Cydia Substrate version 0.9.5100 or lower");
	printf("Karen Tsai (angelXwind) / Linus Yang (laokongzi)\n");
	printf("AppSync Unified is not for piracy.\n");

	printf("Creating queue...\n");
	dispatch_queue_t queue = dispatch_queue_create(dispatch_queue_name, 0);

	printf("Finding installd PID...\n");
	dispatch_async(queue, ^{
		while(TRUE) {
			/* XXX this is processor intensive momentarily until said process starts, should gate */
			boolean_t res = find_process(process_name, &process_pid);
			if(res)
				break;
		}
	});

	printf("Waiting for queue to come back...\n");
	/* wait for queue to come back */
	dispatch_sync(queue, ^{});

	printf("installd PID is %d\n", process_pid);

	printf("Injecting AppSyncUnified.dylib into installd...\n");
	inject_dylib(cynject_path, process_pid, dylib_path);
	
	return 0;
}