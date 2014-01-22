/*
 *    AppSync for iOS 7
 *    https://github.com/linusyang/AppSync
 *
 *    Cydia Substrate tweak for arbitrary IPA package sync
 *    Copyright (c) 2014 Linus Yang <laokongzi@gmail.com>
 *
 *    AppSync is NOT for piracy. Use it legally.
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
 *
 */

#import <substrate.h>
#import <mach-o/dyld.h>

#define INSTALLD_PATH "/usr/libexec/installd"
#define INSTALLD_LEN 21
#define LIBMIS_PATH "/usr/lib/libmis.dylib"

uintptr_t (*MISValidateSignatureAndCopyInfo)(NSString *path, uintptr_t b, NSDictionary **info);
uintptr_t (*original_MISValidateSignatureAndCopyInfo)(NSString *path, uintptr_t b, NSDictionary **info);

uintptr_t AppSyncValidateSignatureAndCopyInfo(NSString *path, uintptr_t b, NSDictionary **info)
{
    original_MISValidateSignatureAndCopyInfo(path, b, info);
    return 0;
}

%ctor {
    if (strncmp(_dyld_get_image_name(0), INSTALLD_PATH, INSTALLD_LEN) == 0) {
        do {
            void *handle(dlopen(LIBMIS_PATH, RTLD_LAZY | RTLD_NOLOAD));
            if (handle == NULL) {
                break;
            }

            MISValidateSignatureAndCopyInfo = reinterpret_cast<uintptr_t (*)(NSString *, uintptr_t, NSDictionary **)>(dlsym(handle, "MISValidateSignatureAndCopyInfo"));
            if (MISValidateSignatureAndCopyInfo == NULL) {
                break;
            }

            MSHookFunction(MISValidateSignatureAndCopyInfo, AppSyncValidateSignatureAndCopyInfo, &original_MISValidateSignatureAndCopyInfo);
        } while (0);
    }
}
