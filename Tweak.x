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

/* Minimal Cydia Substrate header */
typedef const void *MSImageRef;
MSImageRef MSGetImageByName(const char *file);
void *MSFindSymbol(MSImageRef image, const char *name);
void MSHookFunction(void *symbol, void *replace, void **result);

#define DECL_FUNC(name, ret, ...) \
    static ret (*original_ ## name)(__VA_ARGS__); \
    ret custom_ ## name(__VA_ARGS__)
#define HOOK_FUNC(name) do { \
    void *_ ## name = MSFindSymbol(image, "_" #name); \
    if (_ ## name == NULL) { \
        NSLog(@"AppSync: Failed to load symbol: " #name "."); \
        return; \
    } \
    MSHookFunction(_ ## name, (void *) custom_ ## name, (void **) &original_ ## name); \
} while(0)

DECL_FUNC(MISValidateSignatureAndCopyInfo, uintptr_t, NSString *path, uintptr_t b, NSDictionary **info)
{
    original_MISValidateSignatureAndCopyInfo(path, b, info);
    return 0;
}

%ctor {
    MSImageRef image = MSGetImageByName("/usr/lib/libmis.dylib");
    if (image == NULL) {
        NSLog(@"AppSync: Failed to load libmis.dylib.");
        return;
    }
    HOOK_FUNC(MISValidateSignatureAndCopyInfo);
}
