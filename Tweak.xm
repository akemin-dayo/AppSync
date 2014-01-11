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
