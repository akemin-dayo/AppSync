#import <Foundation/Foundation.h>

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"AppSync Unified [dylib-FrontBoard] [DEBUG]: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif

// Located in iOS 14.x and above's FrontBoardServices.framework
%hook FBSSignatureValidationService
-(NSUInteger) trustStateForApplication:(id)application {
	LOG(@"Original response for FBSSignatureValidationService trustStateForApplication: application == %@, retval == %lu", application, (unsigned long)%orig(application));
	// Returns 8 for a trusted, valid app.
	// Returns 4 when showing the 「"アプリ"はもう利用できません」 message.
	return 8;
}
%end

// Located in iOS 9.3.x 〜 iOS 13.x's FrontBoard.framework
%hook FBApplicationTrustData
-(NSUInteger) trustStateWithTrustRequiredReasons:(NSUInteger *)reasons {
	LOG(@"Original response for FBApplicationTrustData trustStateWithTrustRequiredReasons: reasons == %lu, retval == %lu", (unsigned long)reasons, (unsigned long)%orig(reasons));
	// Returns 2 for a trusted, valid app.
	return 2;
}

-(NSUInteger) trustState {
	LOG(@"Original response for FBApplicationTrustData trustState: retval == %lu", (unsigned long)%orig());
	return 2;
}
%end

%ctor {
	LOG(@"kCFCoreFoundationVersionNumber = %f", kCFCoreFoundationVersionNumber);
}
