// Heavily modified version of: https://github.com/bazad/blanket/blob/master/amfidupe/cdhash.h

#ifndef BLANKET__AMFID__CDHASH_H_
#define BLANKET__AMFID__CDHASH_H_

#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/NSObjCRuntime.h>

#include <stdbool.h>
#include <stdlib.h>

#include "cs_blobs.h"

/*
 * compute_cdhash
 *
 * Description:
 * 	Compute the cdhash of a Mach-O file.
 *
 * Parameters:
 * 	file				The contents of the Mach-O file.
 * 	size				The size of the Mach-O file.
 * 	cdhash			out	On return, contains the cdhash of the file. Must be
 * 					CS_CDHASH_LEN bytes.
 */
typedef uint8_t amfid_cdhash_t[CS_CDHASH_LEN];

bool compute_cdhash(const void *file, size_t size, void *cdhash);
bool find_cdhash(const char *path, amfid_cdhash_t *cdhash);

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"AppSync Unified [cdhash] [DEBUG]: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif
#define DEBUG_TRACE(level, fmt, ...)	LOG(@ fmt, ##__VA_ARGS__);
#define INFO(fmt, ...)		LOG(@ fmt, ##__VA_ARGS__)
#define WARNING(fmt, ...)	LOG(@ fmt, ##__VA_ARGS__)
#define ERROR(fmt, ...)		LOG(@ fmt, ##__VA_ARGS__)

#endif
