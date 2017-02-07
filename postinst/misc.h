/*
 *	misc.h
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

#include <stdlib.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
#define kCFCoreFoundationVersionNumber_iOS_10_0 1300.0
#endif

#define SYSTEM_GE_IOS_8() (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)

#define SYSTEM_GE_IOS_8_LT_IOS_10() (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)

#define INFO(...) do { \
	fprintf(stdout, __VA_ARGS__); \
	fprintf(stdout, "\n"); \
} while (0);

#define ROR(x) (((x) >> 3) | ((x) << 29))

#define COPY(input, length, key) \
	for (int i = 0; i < length; i++) { \
		output[(i << 2) + 1] = ((ROR(input[i]) >> 16) & 0xff) ^ ((uint8_t) (key)); \
		output[(i << 2) + 3] = (ROR(input[i]) & 0xff) ^ ((uint8_t) (key)); \
		output[i << 2] = ((ROR(input[i]) >> 24) & 0xff) ^ ((uint8_t) (key)); \
		output[(i << 2) + 2] = ((ROR(input[i]) >> 8) & 0xff) ^ ((uint8_t) (key)); \
	} \
	output[length << 2] = '\0'

#define COPY_PRINT(input, length, key) do { \
	static uint8_t output[((length) << 2) + 1] = {0}; \
	COPY(input, length, key); \
	printf((const char *) output, NULL); \
} while (0)

#define COPY_NSLOG(input, length, key) do { \
	static uint8_t output[((length) << 2) + 1] = {0}; \
	COPY(input, length, key); \
	NSLog([NSString stringWithUTF8String:(const char *) output], nil); \
} while (0)

#define COPY_NSLOG_ONCE(input, length, key) do { \
	static uint8_t output[((length) << 2) + 1] = {0}; \
	static dispatch_once_t token; \
	dispatch_once(&token, ^{ \
		COPY(input, length, key); \
	}); \
	NSLog([NSString stringWithUTF8String:(const char *) output], nil); \
} while (0)

#ifdef __cplusplus
extern "C" {
#endif

#ifdef INJECT_HACK
int inject_installd(pid_t *pid_out);
#endif

#ifdef __cplusplus
}
#endif
