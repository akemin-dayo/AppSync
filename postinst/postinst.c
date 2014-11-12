/*
 *    postinst.c
 *    AppSync Unified
 *
 *    https://github.com/angelXwind/AppSync
 *    http://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified
 *
 *    Copyright (c) 2014 Linus Yang <laokongzi+appsync@gmail.com>, Karen Tsai <angelXwind@angelxwind.net>
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

#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include "misc.h"

#define PLIST_PATH_IOS_8 "/Library/LaunchDaemons/com.apple.mobile.installd.plist"
#define PLIST_PATH "/System" PLIST_PATH_IOS_8

#ifdef BUILD_POSTINST
#define kCopyrightKey (0x13)
#define kCopyrightLength 23
static const uint32_t kCopyrightBytes[kCopyrightLength] = {0x931b1a02, 0x53eb819b, 0xabe3099b, 0xd2e2019b, 0x319b3bd9, 0xbe333a3, 0xd99959eb, 0x10ca83e1, 0x1b530bd3, 0xa3db399b, 0xdb81d199, 0x9191139, 0x9afbd3e9, 0x33019a53, 0x93eba0cb, 0xc9c99a31, 0x2b19ad2, 0x399afab2, 0xa292fafa, 0x51f99aea, 0xe19a1ad2, 0xa928252, 0x99c9c8c9};

#ifdef INJECT_HACK
#include <sys/stat.h>
#define DEFAULT_WAIT 1
#define MAX_TRY 15
#endif
#endif

static int run_launchctl(const char *path, const char *cmd)
{
    const char *args[] = {"/bin/launchctl", cmd, path, NULL};
    pid_t pid;
    int stat;
    posix_spawn(&pid, args[0], NULL, NULL, (char **) args, NULL);
    waitpid(pid, &stat, 0);
    return stat;
}

int main(int argc, const char **argv)
{
#ifdef BUILD_POSTINST
    COPY_PRINT(kCopyrightBytes, kCopyrightLength, kCopyrightKey);
#endif
    if (geteuid() != 0) {
        INFO("fatal: must be run as root, quit");
        return 1;
    }
    if (SYSTEM_GE_IOS_8()) {
        run_launchctl(PLIST_PATH_IOS_8, "unload");
        run_launchctl(PLIST_PATH_IOS_8, "load");
#ifdef INJECT_HACK
#ifdef BUILD_RUNONCE
        chown("/Library/LaunchDaemons/com.linusyang.appsync.plist", 0, 0);
        chmod("/Library/LaunchDaemons/com.linusyang.appsync.plist", 0644);
        chmod("/usr/bin/appsync", 0755);
#endif
#ifdef BUILD_POSTINST
        INFO("Manually injecting for iOS 8...");
        pid_t pid = -1;
        int status = -1;
        int tried = 0;
        do {
            sleep(DEFAULT_WAIT);
            status = inject_installd(&pid);
            tried++;
            INFO("Inject installd (%d) with return %d", pid, status);
        } while (tried < MAX_TRY && (pid == -1 || status != 0));
        if (pid == -1 || status != 0) {
#ifdef BUILD_RUNONCE
            INFO("Inject failed, try to reinstall the package");
#else
            INFO("Inject failed, try again");
#endif
        }
#else
        run_launchctl("/Library/LaunchDaemons/com.linusyang.appsync.plist", "unload");
#endif
#endif
    } else {
        run_launchctl(PLIST_PATH, "unload");
        run_launchctl(PLIST_PATH, "load");
#ifdef INJECT_HACK
#ifdef BUILD_POSTINST
        unlink("/Library/LaunchDaemons/com.linusyang.appsync.plist");
        unlink("/usr/bin/appsync");
#endif
#endif
    }
    return 0;
}
