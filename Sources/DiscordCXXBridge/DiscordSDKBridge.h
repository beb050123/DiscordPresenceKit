#ifndef DiscordSDKBridge_h
#define DiscordSDKBridge_h

#import <Foundation/Foundation.h>

/// Bridge class for interacting with the Discord SDK using the C API.
@interface DiscordSDKBridge : NSObject

/// Initializes the Discord SDK with the given application ID.
/// @param applicationID The Discord application ID (as a string, will be converted to uint64).
/// @param error Pointer to an error object that will be set on failure.
/// @return YES if initialization succeeded, NO otherwise.
- (BOOL)initializeWithApplicationID:(NSString *)applicationID
                              error:(NSError **)error;

/// Updates the Rich Presence activity.
/// @param details Primary activity description (e.g. "In a match").
/// @param state Secondary status (e.g. "Ranked – Solo Queue").
/// @param startTimestamp Start timestamp for elapsed time (Unix epoch in seconds).
/// @param endTimestamp End timestamp for remaining time (Unix epoch in seconds).
/// @param largeImageKey Key for the large image asset.
/// @param largeText Hover text for large image.
/// @param smallImageKey Key for the small image asset.
/// @param smallText Hover text for small image.
/// @param button1Label Label for first button.
/// @param button1Url URL for first button.
/// @param button2Label Label for second button.
/// @param button2Url URL for second button.
/// @param activityType Activity type (0=Playing, 2=Listening, 3=Watching, 5=Competing).
/// @param applicationName Override for application name.
/// @param error Pointer to an error object that will be set on failure.
/// @return YES if the update was sent successfully, NO otherwise.
- (BOOL)updatePresenceWithDetails:(NSString *)details
                           state:(NSString *)state
                  startTimestamp:(NSNumber *)startTimestamp
                    endTimestamp:(NSNumber *)endTimestamp
                   largeImageKey:(NSString *)largeImageKey
                     largeText:(NSString *)largeText
                   smallImageKey:(NSString *)smallImageKey
                     smallText:(NSString *)smallText
                  button1Label:(NSString *)button1Label
                   button1Url:(NSString *)button1Url
                  button2Label:(NSString *)button2Label
                   button2Url:(NSString *)button2Url
                    activityType:(NSInteger)activityType
                applicationName:(NSString *)applicationName
                         error:(NSError **)error;

/// Runs pending callbacks from the Discord SDK.
/// Should be called periodically (e.g., every 1-2 seconds).
- (void)runCallbacks;

/// Shuts down the Discord SDK and cleans up resources.
- (void)shutdown;

@end

#endif /* DiscordSDKBridge_h */
