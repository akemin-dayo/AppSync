/* ldid - (Mach-O) Link-Loader Identity Editor
 * Copyright (C) 2007-2012 Jay Freeman (saurik)

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/

#include "dump.h"
#include <sys/stat.h>
#include <sys/mman.h>
#include <vector>

#define _packed \
	__attribute__((packed))

#define _not(type) \
	((type) ~ (type) 0)

#define FAT_MAGIC 0xcafebabe
#define FAT_CIGAM 0xbebafeca
#define MH_MAGIC 0xfeedface
#define MH_CIGAM 0xcefaedfe
#define MH_MAGIC_64 0xfeedfacf
#define MH_CIGAM_64 0xcffaedfe
#define MH_EXECUTE	0x2
#define MH_DYLIB	  0x6
#define MH_BUNDLE	 0x8
#define LC_CODE_SIGNATURE	 uint32_t(0x1d)
#define CSSLOT_ENTITLEMENTS   uint32_t(5)

template <typename Type_>
struct Iterator_ {
	typedef typename Type_::const_iterator Result;
};

#define _foreach(item, list) \
	for (bool _stop(true); _stop; ) \
		for (const __typeof__(list) &_list = (list); _stop; _stop = false) \
			for (Iterator_<__typeof__(list)>::Result _item = _list.begin(); _item != _list.end(); ++_item) \
				for (bool _suck(true); _suck; _suck = false) \
					for (const __typeof__(*_item) &item = *_item; _suck; _suck = false)

struct fat_header {
	uint32_t magic;
	uint32_t nfat_arch;
} _packed;

struct fat_arch {
	uint32_t cputype;
	uint32_t cpusubtype;
	uint32_t offset;
	uint32_t size;
	uint32_t align;
} _packed;

struct mach_header {
	uint32_t magic;
	uint32_t cputype;
	uint32_t cpusubtype;
	uint32_t filetype;
	uint32_t ncmds;
	uint32_t sizeofcmds;
	uint32_t flags;
} _packed;

struct segment_command {
	uint32_t cmd;
	uint32_t cmdsize;
	char segname[16];
	uint32_t vmaddr;
	uint32_t vmsize;
	uint32_t fileoff;
	uint32_t filesize;
	uint32_t maxprot;
	uint32_t initprot;
	uint32_t nsects;
	uint32_t flags;
} _packed;

struct segment_command_64 {
	uint32_t cmd;
	uint32_t cmdsize;
	char segname[16];
	uint64_t vmaddr;
	uint64_t vmsize;
	uint64_t fileoff;
	uint64_t filesize;
	uint32_t maxprot;
	uint32_t initprot;
	uint32_t nsects;
	uint32_t flags;
} _packed;

struct section {
	char sectname[16];
	char segname[16];
	uint32_t addr;
	uint32_t size;
	uint32_t offset;
	uint32_t align;
	uint32_t reloff;
	uint32_t nreloc;
	uint32_t flags;
	uint32_t reserved1;
	uint32_t reserved2;
} _packed;

struct section_64 {
	char sectname[16];
	char segname[16];
	uint64_t addr;
	uint64_t size;
	uint32_t offset;
	uint32_t align;
	uint32_t reloff;
	uint32_t nreloc;
	uint32_t flags;
	uint32_t reserved1;
	uint32_t reserved2;
} _packed;

struct linkedit_data_command {
	uint32_t cmd;
	uint32_t cmdsize;
	uint32_t dataoff;
	uint32_t datasize;
} _packed;

struct load_command {
	uint32_t cmd;
	uint32_t cmdsize;
} _packed;

struct BlobIndex {
	uint32_t type;
	uint32_t offset;
} _packed;

struct Blob {
	uint32_t magic;
	uint32_t length;
} _packed;

struct SuperBlob {
	struct Blob blob;
	uint32_t count;
	struct BlobIndex index[];
} _packed;

static uint32_t Swap_(uint32_t value) {
	value = ((value >>  8) & 0x00ff00ff) |
			((value <<  8) & 0xff00ff00);
	value = ((value >> 16) & 0x0000ffff) |
			((value << 16) & 0xffff0000);
	return value;
}

static bool little_(true);

static uint32_t Swap(uint32_t value) {
	return little_ ? Swap_(value) : value;
}

template <typename Target_>
class Pointer;

class Data {
  private:
	void *base_;
	size_t size_;

  protected:
	bool swapped_;

  public:
	Data(void *base, size_t size) :
		base_(base),
		size_(size),
		swapped_(false)
	{
	}

	uint32_t Swap(uint32_t value) const {
		return swapped_ ? Swap_(value) : value;
	}

	int32_t Swap(int32_t value) const {
		return Swap(static_cast<uint32_t>(value));
	}

	void *GetBase() const {
		return base_;
	}

	size_t GetSize() const {
		return size_;
	}
};

class MachHeader :
	public Data
{
  private:
	bool bits64_;

	struct mach_header *mach_header_;
	struct load_command *load_command_;

  public:
	MachHeader(void *base, size_t size) :
		Data(base, size)
	{
		mach_header_ = (mach_header *) base;

		switch (Swap(mach_header_->magic)) {
			case MH_CIGAM:
				swapped_ = !swapped_;
			case MH_MAGIC:
				bits64_ = false;
			break;

			case MH_CIGAM_64:
				swapped_ = !swapped_;
			case MH_MAGIC_64:
				bits64_ = true;
			break;

			default:
				throw "unknown Mach-O magic";
		}

		void *post = mach_header_ + 1;
		if (bits64_)
			post = (uint32_t *) post + 1;
		load_command_ = (struct load_command *) post;

		if (!(Swap(mach_header_->filetype) == MH_EXECUTE ||
			Swap(mach_header_->filetype) == MH_DYLIB ||
			Swap(mach_header_->filetype) == MH_BUNDLE)) {
			throw "bad Mach-O file type";
		}
	}

	struct mach_header *operator ->() const {
		return mach_header_;
	}

	std::vector<struct load_command *> GetLoadCommands() const {
		std::vector<struct load_command *> load_commands;

		struct load_command *load_command = load_command_;
		for (uint32_t cmd = 0; cmd != Swap(mach_header_->ncmds); ++cmd) {
			load_commands.push_back(load_command);
			load_command = (struct load_command *) ((uint8_t *) load_command + Swap(load_command->cmdsize));
		}

		return load_commands;
	}
};

class FatMachHeader :
	public MachHeader
{
  private:
	fat_arch *fat_arch_;

  public:
	FatMachHeader(void *base, size_t size, fat_arch *fat_arch) :
		MachHeader(base, size),
		fat_arch_(fat_arch)
	{
	}
};

class FatHeader :
	public Data
{
  private:
	fat_header *fat_header_;
	std::vector<FatMachHeader> mach_headers_;

  public:
	FatHeader(void *base, size_t size) :
		Data(base, size)
	{
		fat_header_ = reinterpret_cast<struct fat_header *>(base);

		if (Swap(fat_header_->magic) == FAT_CIGAM) {
			swapped_ = !swapped_;
			goto fat;
		} else if (Swap(fat_header_->magic) != FAT_MAGIC) {
			fat_header_ = NULL;
			mach_headers_.push_back(FatMachHeader(base, size, NULL));
		} else fat: {
			size_t fat_narch = Swap(fat_header_->nfat_arch);
			fat_arch *fat_arch = reinterpret_cast<struct fat_arch *>(fat_header_ + 1);
			size_t arch;
			for (arch = 0; arch != fat_narch; ++arch) {
				uint32_t arch_offset = Swap(fat_arch->offset);
				uint32_t arch_size = Swap(fat_arch->size);
				mach_headers_.push_back(FatMachHeader((uint8_t *) base + arch_offset, arch_size, fat_arch));
				++fat_arch;
			}
		}
	}

	std::vector<FatMachHeader> &GetMachHeaders() {
		return mach_headers_;
	}

	bool IsFat() const {
		return fat_header_ != NULL;
	}

	struct fat_header *operator ->() const {
		return fat_header_;
	}
};

static void *map(const char *path, size_t offset, size_t size, size_t *psize) {
	int fd;
	void *base = NULL;

	fd = open(path, O_RDONLY);
	if (fd == -1) {
		return NULL;
	}

	if (size == _not(size_t)) {
		struct stat stat;
		if (fstat(fd, &stat) == -1) {
			goto fail;
		}
		size = stat.st_size;
	}

	if (psize != NULL)
		*psize = size;

	base = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, offset);
	if (base == MAP_FAILED) {
		base = NULL;
	}

fail:
	close(fd);
	return base;
}

#ifdef DEBUG
	CFStringRef entErrorString(int code) {
		static CFStringRef strings[] = {
			CFSTR("success"),
			CFSTR("argument is null"),
			CFSTR("file read error"),
			CFSTR("malformed Mach-O file"),
			CFSTR("unknown error")
		};
		if (code >= kCopyEntSuccess && code < kCopyEntUnknown) {
			return strings[code];
		}
		return strings[kCopyEntUnknown];
	}
#endif

int copyEntitlementDataFromFile(const char *path, CFMutableDataRef output) {
	if (path == NULL || output == NULL) {
		return kCopyEntArgumentNull;
	}

	static union {
		uint16_t word;
		uint8_t byte[2];
	} endian = {1};

	little_ = endian.byte[0];

	size_t size;
	void *base(map(path, 0, _not(size_t), &size));
	if (base == NULL) {
		return kCopyEntMapFail;
	}

	int result = kCopyEntUnknown;
	try {
		FatHeader fat_header(base, size);
		struct linkedit_data_command *signature(NULL);

		_foreach (mach_header, fat_header.GetMachHeaders()) {
			_foreach (load_command, mach_header.GetLoadCommands()) {
				uint32_t cmd(mach_header.Swap(load_command->cmd));
				if (cmd == LC_CODE_SIGNATURE) {
					signature = reinterpret_cast<struct linkedit_data_command *>(load_command);
					if (signature != NULL) {			   
						uint32_t data = mach_header.Swap(signature->dataoff);

						uint8_t *top = reinterpret_cast<uint8_t *>(mach_header.GetBase());
						uint8_t *blob = top + data;
						struct SuperBlob *super = reinterpret_cast<struct SuperBlob *>(blob);

						if ((super->count) > 0) {
							for (size_t index(0); index != Swap(super->count); ++index) {
								if (Swap(super->index[index].type) == CSSLOT_ENTITLEMENTS) {
									uint32_t begin = Swap(super->index[index].offset);
									struct Blob *entitlements = reinterpret_cast<struct Blob *>(blob + begin);
									CFDataAppendBytes(output, (const uint8_t *) (entitlements + 1), Swap(entitlements->length) - sizeof(struct Blob));
								}
							}
						}

						result = kCopyEntSuccess;
						goto cleanup;
					}
				}
			}
		}

	} catch (const char *exception) {
#ifdef DEBUG
		if (exception != NULL) {
			CFLog(kCFLogLevelWarning, CFSTR("failed to process binary: %s"), exception);
		}
#endif
		result = kCopyEntMachO;
	}

cleanup:
	munmap(base, size);
	return result;
}

#ifdef DUMP_TEST
int main(int argc, const char *argv[]) {
	if (argc < 2) {
		fprintf(stderr, "%s: missing arguments\n", argv[0]);
		return 1;
	}
	CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
	int ret = copyEntitlementDataFromFile(argv[1], data);
	if (ret == kCopyEntSuccess) {
		CFStringRef str = CFStringCreateFromExternalRepresentation(NULL, data,
			kCFStringEncodingUTF8);
		CFShow(str);
		CFRelease(str);
	} else {
#ifdef DEBUG
		CFLog(kCFLogLevelError, CFSTR("failed to dump (%@)"), entErrorString(ret));
#else
		fprintf(stderr, "%s: failed to dump (error %d)\n", argv[0], ret);
#endif
	}
	CFRelease(data);
	return 0;
}
#endif
