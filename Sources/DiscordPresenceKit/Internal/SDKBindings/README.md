# Discord SDK Bindings

This directory contains the internal bindings to the Discord Social SDK.

## Integration Status

**Currently a placeholder.** The actual C++ SDK integration is not yet implemented.

## Integration Plan

When integrating the Discord Social SDK:

1. **Add Objective-C++ files** (`.mm`) that:
   - Import the Discord SDK C++ headers
   - Expose Objective-C interfaces to Swift
   - Handle C++ memory management and callbacks

2. **Update `DiscordSDKClient.swift`** to:
   - Call the Objective-C++ wrapper methods
   - Handle SDK callbacks and errors
   - Convert between Swift and C++ types

3. **Update `Package.swift`** to:
   - Link against the Discord SDK library
   - Include the SDK headers search path
   - Handle C++ compilation

## Discord Social SDK

Download from: https://discord.com/developers/docs/social-sdk

Place files in `DiscordSDK/`:
- Headers in `DiscordSDK/include/`
- Libraries in `DiscordSDK/lib/`

## C++ Bridge Example

```objc
// DiscordSDKWrapper.mm

#import <Foundation/Foundation.h>
#import "discordpp/Client.h"

@interface DiscordSDKWrapper : NSObject

- (instancetype)initWithApplicationID:(NSString *)applicationID;
- (void)updatePresenceWithDetails:(NSString *)details
                            state:(NSString *)state
                       completion:(void (^)(BOOL success))completion;
- (void)runCallbacks;
- (void)shutdown;

@end
```

## Thread Safety

The Discord SDK is not thread-safe. All SDK calls must be made from
the same thread/queue. The public `DiscordClient` protocol documents
this requirement for consumers.
