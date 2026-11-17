//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef bridge_h
#define bridge_h

#include "worse_query.h"
#include "pathleak.h"

// some stuff here is from https://github.com/jailbreakdotparty/Erosion/blob/main/Erosion/bridge.h

typedef struct CF_BRIDGED_TYPE(id) __SecTask *SecTaskRef;

SecTaskRef _Nullable SecTaskCreateFromSelf(CFAllocatorRef _Nullable allocator) CF_RETURNS_RETAINED;

CFTypeRef _Nullable SecTaskCopyValueForEntitlement(SecTaskRef _Nonnull task, CFStringRef _Nonnull entitlement, CFErrorRef _Nullable * _Nullable error) CF_RETURNS_RETAINED;

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (bool)openApplicationWithBundleID:(NSString*)bundleID;
@end

#endif /* bridge_h */
