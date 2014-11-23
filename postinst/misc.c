/*
 *	misc.c
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

#include <stdio.h>
#include <string.h>
#include <spawn.h>
#include <sys/sysctl.h>
#include "misc.h"

#define EXIT_PID_FAIL 1

int inject_installd(pid_t *pid_out)
{
	/* Find pid of installd */
	if (pid_out != NULL) {
		*pid_out = -1;
	}
	pid_t pid_installd = -1;
	struct kinfo_proc *procs = NULL;
	size_t size = 0;
	int status = 0;
	int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
	status = sysctl(mib, 4, NULL, &size, NULL, 0);
	if (status != 0 || size == 0) {
		return EXIT_PID_FAIL;
	}
	procs = (struct kinfo_proc *) malloc(size);
	status = sysctl(mib, 4, procs, &size, NULL, 0);
	if (status == 0) {
		int nproc = size / sizeof(struct kinfo_proc);
		for (int i = 0; i < nproc; i++) {
			pid_t p_pid = procs[i].kp_proc.p_pid;
			char *p_name = procs[i].kp_proc.p_comm;
			if (strcmp("installd", p_name) == 0) {
				pid_installd = p_pid;
				break;
			}
		}
	}
	if (procs != NULL) {
		free(procs);
	}
	if (pid_installd == -1) {
		return EXIT_PID_FAIL;
	}
	if (pid_out != NULL) {
		*pid_out = pid_installd;
	}

	/* Try to inject installd with cynject */
	char buf[16] = {0};
	snprintf(buf, 16, "%d", pid_installd);
	const char *args[] = {"/usr/bin/cynject", buf, "/Library/MobileSubstrate/MobileSubstrate.dylib", NULL};
	pid_t pid;
	int stat;
	posix_spawn(&pid, args[0], NULL, NULL, (char **) args, NULL);
	waitpid(pid, &stat, 0);
	
	return stat;
}
