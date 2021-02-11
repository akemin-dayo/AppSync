// Heavily modified version of: https://github.com/bazad/blanket/blob/master/amfidupe/cdhash.c

/*
 * Cdhash computation
 * ------------------
 *
 *  The amfid patch needs to be able to compute the cdhash of a binary.
 *  This code is heavily based on the implementation in Ian Beer's triple_fetch project [1] and on
 *  the source of XNU [2].
 *
 *  [1]: https://bugs.chromium.org/p/project-zero/issues/detail?id=1247
 *  [2]: https://opensource.apple.com/source/xnu/xnu-4570.41.2/bsd/kern/ubc_subr.c.auto.html
 *
 */
#include "cdhash.h"

#include <sys/mman.h>
#include <sys/stat.h>

#include <CommonCrypto/CommonCrypto.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <mach-o/fat.h>
#include <mach/machine.h>

#ifndef __LP64__
#define mach_header_host	mach_header
#else
#define mach_header_host	mach_header_64
#endif

// Check whether the file looks like a Mach-O file.
static bool
macho_identify(const struct mach_header_host *mh, size_t size) {
	// Check the file size and magic.
	if (size < 0x1000 || mh->magic != MH_MAGIC_64) {
		return false;
	}
	return true;
}

// Perform some basic validation on the Mach-O header. This is NOT enough to be sure that the
// Mach-O is safe!
static bool
macho_validate(const struct mach_header_host *mh, size_t size) {
	if (!macho_identify(mh, size)) {
		return false;
	}
	// Check that the load commands fit in the file.
	if (mh->sizeofcmds > size) {
		return false;
	}
	// Check that each load command fits in the header.
	const uint8_t *lc_p = (const uint8_t *)(mh + 1);
	const uint8_t *lc_end = lc_p + mh->sizeofcmds;
	while (lc_p < lc_end) {
		const struct load_command *lc = (const struct load_command *)lc_p;
		if (lc->cmdsize >= 0x80000000) {
			return false;
		}
		const uint8_t *lc_next = lc_p + lc->cmdsize;
		if (lc_next > lc_end) {
			return false;
		}
		lc_p = lc_next;
	}
	return true;
}

// Get the next load command in a Mach-O file.
static const void *
macho_next_load_command(const struct mach_header_host *mh, size_t size, const void *lc) {
	const struct load_command *next = lc;
	if (next == NULL) {
		next = (const struct load_command *)(mh + 1);
	} else {
		next = (const struct load_command *)((uint8_t *)next + next->cmdsize);
	}
	if ((uintptr_t)next >= (uintptr_t)(mh + 1) + mh->sizeofcmds) {
		next = NULL;
	}
	return next;
}

// Find the next load command in a Mach-O file matching the given type.
static const void *
macho_find_load_command(const struct mach_header_host *mh, size_t size,
		uint32_t command, const void *lc) {
	const struct load_command *loadcmd = lc;
	for (;;) {
		loadcmd = macho_next_load_command(mh, size, loadcmd);
		if (loadcmd == NULL || loadcmd->cmd == command) {
			return loadcmd;
		}
	}
}

// Validate a CS_CodeDirectory and return its true length.
static size_t
cs_codedirectory_validate(CS_CodeDirectory *cd, size_t size) {
	// Make sure we at least have a CS_CodeDirectory. There's an end_earliest parameter, but
	// XNU doesn't seem to use it in cs_validate_codedirectory().
	if (size < sizeof(*cd)) {
		ERROR("CS_CodeDirectory is too small");
		return 0;
	}
	// Validate the magic.
	uint32_t magic = ntohl(cd->magic);
	if (magic != CSMAGIC_CODEDIRECTORY) {
		ERROR("CS_CodeDirectory has incorrect magic");
		return 0;
	}
	// Validate the length.
	uint32_t length = ntohl(cd->length);
	if (length > size) {
		ERROR("CS_CodeDirectory has invalid length");
		return 0;
	}
	return length;
}

// Validate a CS_SuperBlob and return its true length.
static size_t
cs_superblob_validate(CS_SuperBlob *sb, size_t size) {
	// Make sure we at least have a CS_SuperBlob.
	if (size < sizeof(*sb)) {
		ERROR("CS_SuperBlob is too small");
		return 0;
	}
	// Validate the magic.
	uint32_t magic = ntohl(sb->magic);
	if (magic != CSMAGIC_EMBEDDED_SIGNATURE) {
		ERROR("CS_SuperBlob has incorrect magic");
		return 0;
	}
	// Validate the length.
	uint32_t length = ntohl(sb->length);
	if (length > size) {
		ERROR("CS_SuperBlob has invalid length");
		return 0;
	}
	uint32_t count = ntohl(sb->count);
	// Validate the count.
	CS_BlobIndex *index = &sb->index[count];
	if (count >= 0x10000 || (uintptr_t)index > (uintptr_t)sb + size) {
		ERROR("CS_SuperBlob has invalid count");
		return 0;
	}
	return length;
}

// Compute the cdhash of a code directory using SHA1.
static void
cdhash_sha1(CS_CodeDirectory *cd, size_t length, void *cdhash) {
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cd, (CC_LONG) length, digest);
	memcpy(cdhash, digest, CS_CDHASH_LEN);
}

// Compute the cdhash of a code directory using SHA256.
static void
cdhash_sha256(CS_CodeDirectory *cd, size_t length, void *cdhash) {
	uint8_t digest[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(cd, (CC_LONG) length, digest);
	memcpy(cdhash, digest, CS_CDHASH_LEN);
}

// Compute the cdhash from a CS_CodeDirectory.
static bool
cs_codedirectory_cdhash(CS_CodeDirectory *cd, size_t size, void *cdhash) {
	size_t length = ntohl(cd->length);
	switch (cd->hashType) {
		case CS_HASHTYPE_SHA1:
			DEBUG_TRACE(2, "Using SHA1");
			cdhash_sha1(cd, length, cdhash);
			return true;
		case CS_HASHTYPE_SHA256:
			DEBUG_TRACE(2, "Using SHA256");
			cdhash_sha256(cd, length, cdhash);
			return true;
	}
	ERROR("Unsupported hash type %d", cd->hashType);
	return false;
}

// Get the rank of a code directory.
static unsigned
cs_codedirectory_rank(CS_CodeDirectory *cd) {
	// The supported hash types, ranked from least to most preferred. From XNU's
	// bsd/kern/ubc_subr.c.
	static uint32_t ranked_hash_types[] = {
		CS_HASHTYPE_SHA1,
		CS_HASHTYPE_SHA256_TRUNCATED,
		CS_HASHTYPE_SHA256,
		CS_HASHTYPE_SHA384,
	};
	// Define the rank of the code directory as its index in the array plus one.
	for (unsigned i = 0; i < sizeof(ranked_hash_types) / sizeof(ranked_hash_types[0]); i++) {
		if (ranked_hash_types[i] == cd->hashType) {
			return (i + 1);
		}
	}
	return 0;
}

// Compute the cdhash from a CS_SuperBlob.
static bool
cs_superblob_cdhash(CS_SuperBlob *sb, size_t size, void *cdhash) {
	// Iterate through each index searching for the best code directory.
	CS_CodeDirectory *best_cd = NULL;
	unsigned best_cd_rank = 0;
	size_t best_cd_size = 0;
	uint32_t count = ntohl(sb->count);
	for (size_t i = 0; i < count; i++) {
		CS_BlobIndex *index = &sb->index[i];
		uint32_t type = ntohl(index->type);
		uint32_t offset = ntohl(index->offset);
		// Validate the offset.
		if (offset > size) {
			ERROR("CS_SuperBlob has out-of-bounds CS_BlobIndex");
			return false;
		}
		// Look for a code directory.
		if (type == CSSLOT_CODEDIRECTORY ||
				(CSSLOT_ALTERNATE_CODEDIRECTORIES <= type && type < CSSLOT_ALTERNATE_CODEDIRECTORY_LIMIT)) {
			CS_CodeDirectory *cd = (CS_CodeDirectory *)((uint8_t *)sb + offset);
			size_t cd_size = cs_codedirectory_validate(cd, size - offset);
			if (cd_size == 0) {
				return false;
			}
			DEBUG_TRACE(2, "CS_CodeDirectory { hashType = %u }", cd->hashType);
			// Rank the code directory to see if it's better than our previous best.
			unsigned cd_rank = cs_codedirectory_rank(cd);
			if (cd_rank > best_cd_rank) {
				best_cd = cd;
				best_cd_rank = cd_rank;
				best_cd_size = cd_size;
			}
		}
	}
	// If we didn't find a code directory, error.
	if (best_cd == NULL) {
		ERROR("CS_SuperBlob does not have a code directory");
		return false;
	}
	// Hash the code directory.
	return cs_codedirectory_cdhash(best_cd, best_cd_size, cdhash);
}

// Compute the cdhash from a csblob.
static bool
csblob_cdhash(CS_GenericBlob *blob, size_t size, void *cdhash) {
	// Make sure we at least have a CS_GenericBlob.
	if (size < sizeof(*blob)) {
		ERROR("CSBlob is too small");
		return false;
	}
	uint32_t magic = ntohl(blob->magic);
	uint32_t length = ntohl(blob->length);
	DEBUG_TRACE(2, "CS_GenericBlob { %08x, %u }, size = %zu", magic, length, size);
	// Make sure the length is sensible.
	if (length > size) {
		ERROR("CSBlob has invalid length");
		return false;
	}
	// Handle the blob.
	bool ok;
	switch (magic) {
		case CSMAGIC_EMBEDDED_SIGNATURE:
			ok = cs_superblob_validate((CS_SuperBlob *)blob, length);
			if (!ok) {
				return false;
			}
			return cs_superblob_cdhash((CS_SuperBlob *)blob, length, cdhash);
		case CSMAGIC_CODEDIRECTORY:
			ok = cs_codedirectory_validate((CS_CodeDirectory *)blob, length);
			if (!ok) {
				return false;
			}
			return cs_codedirectory_cdhash((CS_CodeDirectory *)blob, length, cdhash);
	}
	ERROR("Unrecognized CSBlob magic 0x%08x", magic);
	return false;
}

// Compute the cdhash for a Mach-O file.
static bool
compute_cdhash_macho(const struct mach_header_host *mh, size_t size, void *cdhash) {
	// Find the code signature command.
	const struct linkedit_data_command *cs_cmd =
		macho_find_load_command(mh, size, LC_CODE_SIGNATURE, NULL);
	if (cs_cmd == NULL) {
		ERROR("No code signature");
		return false;
	}
	// Check that the code signature is in-bounds.
	const uint8_t *cs_data = (const uint8_t *)mh + cs_cmd->dataoff;
	const uint8_t *cs_end = cs_data + cs_cmd->datasize;
	if (!((uint8_t *)mh < cs_data && cs_data < cs_end && cs_end <= (uint8_t *)mh + size)) {
		ERROR("Invalid code signature");
		return false;
	}
	// Check that the code signature data looks correct.
	return csblob_cdhash((CS_GenericBlob *)cs_data, cs_end - cs_data, cdhash);
}

bool
compute_cdhash(const void *file, size_t size, void *cdhash) {
	// Try to compute the cdhash for a Mach-O file.
	const struct mach_header_host *mh = file;

	uint32_t fileOffset = 0;
	uint32_t magic = *(uint32_t*)file;
	if (ntohl(magic) == FAT_MAGIC) {
		INFO("Found a fat header!\n");

		// Get the cputype and cpusubtype of the mach_portal binary
		struct mach_header_host *mainMachHeader = (struct mach_header_host *)_dyld_get_image_header(0);
		cpu_type_t mainCpuType = mainMachHeader->cputype & ~CPU_ARCH_MASK;
		cpu_type_t mainCpuSubType = mainMachHeader->cpusubtype & ~CPU_SUBTYPE_MASK;

		struct fat_header *fatHeader = (struct fat_header *)file;
		struct fat_arch *fatArch = (struct fat_arch *)(file + sizeof(struct fat_header));
		for (int i = 0; i < ntohl(fatHeader->nfat_arch); i++, fatArch++) {
			cpu_type_t cpuType = ntohl(fatArch->cputype) & ~CPU_ARCH_MASK;
			cpu_subtype_t cpuSubType = ntohl(fatArch->cpusubtype) & ~CPU_SUBTYPE_MASK;
			if (cpuType == mainCpuType && cpuSubType == mainCpuSubType) {
				fileOffset = ntohl(fatArch->offset);
				INFO("arm64 arch offset is %u\n", fileOffset);
				fatHeader++;
				break;
			}
		}

		if (fileOffset == 0) {
			ERROR("Arch not found in fat header…\n");
			return false;
		}

		mh = (const struct mach_header_host*)((uintptr_t)file + fileOffset);
	}

	if (macho_identify(mh, size)) {
		if (!macho_validate(mh, size)) {
			ERROR("Bad Mach-O file");
			return false;
		}
		return compute_cdhash_macho(mh, size, cdhash);
	}
	// What is it?
	ERROR("Unrecognized file format");
	return false;
}

bool
find_cdhash(const char *path, amfid_cdhash_t *cdhash) {
	bool success = false;
	size_t fileoff = 0;

	int fd;
	fd = open(path, O_RDONLY);
	if (fd < 0) {
		ERROR("Could not open \"%s\"", path);
		goto fail_0;
	}
	// Get the size of the file.
	struct stat st;
	int err = fstat(fd, &st);
	if (err != 0) {
		ERROR("Could not get the size of \"%s\"", path);
		goto fail_1;
	}
	size_t size = st.st_size;
	assert(fileoff < size);
	// Map the file into memory.
	DEBUG_TRACE(2, "Mapping %s size %zu offset %zu", path, size, fileoff);
	size -= fileoff;
	uint8_t *file = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, fileoff);
	if (file == MAP_FAILED) {
		ERROR("Could not map \"%s\"", path);
		goto fail_1;
	}
	DEBUG_TRACE(3, "file[0] = %llx", *(uint64_t *)file);
	// Compute the cdhash.
	success = compute_cdhash(file, size, cdhash);

	munmap(file, size);
fail_1:
	close(fd);
fail_0:
	return success;
}
