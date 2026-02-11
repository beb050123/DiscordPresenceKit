#import "DiscordSDKBridge.h"
#include "cdiscord.h"
#include <string>

// Discord SDK constants
static const int64_t DISCORD_APP_ID_MIN = 10000000000000000;

// Flag to track if Discord_RunCallbacks has crashed before
// If it crashes once, we stop calling it to prevent repeated crashes
static std::atomic<bool> g_callbacksCrashed{false};
static std::atomic<bool> g_callbacksEverSucceeded{false};

@interface DiscordSDKBridge ()
@property (nonatomic, assign) struct Discord_Client *client;
@property (nonatomic, copy) NSString *applicationID;
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) BOOL hasCalledCallbacksSuccessfully;

// Helper to create Discord_String from NSString
+ (Discord_String)discordStringFromString:(NSString *)string;

// Helper to create Discord_String from nil
+ (Discord_String)discordStringFromNil;

@end

@implementation DiscordSDKBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _client = NULL;
        _isInitialized = NO;
        _hasCalledCallbacksSuccessfully = NO;
    }
    return self;
}

- (void)dealloc {
    [self shutdown];
}

+ (Discord_String)discordStringFromString:(NSString *)string {
    Discord_String ds;
    if (string == nil) {
        ds.ptr = NULL;
        ds.size = 0;
    } else {
        const char *cstr = [string UTF8String];
        ds.ptr = (uint8_t *)cstr;
        ds.size = strlen(cstr);
    }
    return ds;
}

+ (Discord_String)discordStringFromNil {
    Discord_String ds;
    ds.ptr = NULL;
    ds.size = 0;
    return ds;
}

- (BOOL)initializeWithApplicationID:(NSString *)applicationID
                              error:(NSError **)error {
    if (_isInitialized) {
        if (error) {
            *error = [NSError errorWithDomain:@"DiscordPresenceKit"
                                        code:1001
                                    userInfo:@{NSLocalizedDescriptionKey: @"SDK already initialized"}];
        }
        return NO;
    }

    // Parse application ID
    int64_t appID = [applicationID longLongValue];
    if (appID < DISCORD_APP_ID_MIN) {
        if (error) {
            *error = [NSError errorWithDomain:@"DiscordPresenceKit"
                                        code:1002
                                    userInfo:@{NSLocalizedDescriptionKey: @"Invalid application ID"}];
        }
        return NO;
    }

    // Create Discord client
    _client = (struct Discord_Client *)malloc(sizeof(Discord_Client));
    if (!_client) {
        if (error) {
            *error = [NSError errorWithDomain:@"DiscordPresenceKit"
                                        code:1003
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to allocate client"}];
        }
        return NO;
    }

    // Initialize the client structure
    Discord_Client_Init(_client);

    // Set application ID
    Discord_Client_SetApplicationId(_client, (uint64_t)appID);

    // Connect to Discord - this can fail silently if Discord isn't running
    Discord_Client_Connect(_client);

    _applicationID = [applicationID copy];

    // Note: We don't set _isInitialized = YES immediately
    // We'll only mark it as initialized after the first successful callback
    // or successful update. This prevents calling RunCallbacks before
    // the SDK is actually ready.
    _isInitialized = YES;

    return YES;
}

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
                         error:(NSError **)error {

    if (!_isInitialized || !_client) {
        if (error) {
            *error = [NSError errorWithDomain:@"DiscordPresenceKit"
                                        code:2001
                                    userInfo:@{NSLocalizedDescriptionKey: @"SDK not initialized"}];
        }
        return NO;
    }

    @try {
        Discord_Activity activity;
        Discord_Activity_Init(&activity);

        // Set details
        if (details != nil) {
            Discord_String ds = [DiscordSDKBridge discordStringFromString:details];
            Discord_Activity_SetDetails(&activity, &ds);
        }

        // Set state
        if (state != nil) {
            Discord_String ds = [DiscordSDKBridge discordStringFromString:state];
            Discord_Activity_SetState(&activity, &ds);
        }

        // Set timestamps
        bool hasTimestamps = false;
        Discord_ActivityTimestamps timestamps;
        Discord_ActivityTimestamps_Init(&timestamps);

        if (startTimestamp != nil) {
            int64_t startSec = [startTimestamp longLongValue];
            Discord_ActivityTimestamps_SetStart(&timestamps, startSec * 1000); // Convert to milliseconds
            hasTimestamps = true;
        } else if (endTimestamp != nil) {
            int64_t endSec = [endTimestamp longLongValue];
            Discord_ActivityTimestamps_SetEnd(&timestamps, endSec * 1000); // Convert to milliseconds
            hasTimestamps = true;
        }

        if (hasTimestamps) {
            Discord_Activity_SetTimestamps(&activity, &timestamps);
        }

        Discord_ActivityTimestamps_Drop(&timestamps);

        // Set assets
        bool hasAssets = (largeImageKey != nil || smallImageKey != nil);
        Discord_ActivityAssets assets;
        Discord_ActivityAssets_Init(&assets);

        if (largeImageKey != nil) {
            Discord_String ds = [DiscordSDKBridge discordStringFromString:largeImageKey];
            Discord_ActivityAssets_SetLargeImage(&assets, &ds);
            if (largeText != nil) {
                Discord_String textDs = [DiscordSDKBridge discordStringFromString:largeText];
                Discord_ActivityAssets_SetLargeText(&assets, &textDs);
            }
        }

        if (smallImageKey != nil) {
            Discord_String ds = [DiscordSDKBridge discordStringFromString:smallImageKey];
            Discord_ActivityAssets_SetSmallImage(&assets, &ds);
            if (smallText != nil) {
                Discord_String textDs = [DiscordSDKBridge discordStringFromString:smallText];
                Discord_ActivityAssets_SetSmallText(&assets, &textDs);
            }
        }

        if (hasAssets) {
            Discord_Activity_SetAssets(&activity, &assets);
        }

        Discord_ActivityAssets_Drop(&assets);

        // Set buttons (max 2)
        if (button1Label != nil && button1Url != nil) {
            Discord_ActivityButton button;
            Discord_ActivityButton_Init(&button);

            Discord_String labelDs = [DiscordSDKBridge discordStringFromString:button1Label];
            Discord_ActivityButton_SetLabel(&button, labelDs);

            Discord_String urlDs = [DiscordSDKBridge discordStringFromString:button1Url];
            Discord_ActivityButton_SetUrl(&button, urlDs);

            Discord_Activity_AddButton(&activity, &button);
            Discord_ActivityButton_Drop(&button);
        }

        if (button2Label != nil && button2Url != nil) {
            Discord_ActivityButton button;
            Discord_ActivityButton_Init(&button);

            Discord_String labelDs = [DiscordSDKBridge discordStringFromString:button2Label];
            Discord_ActivityButton_SetLabel(&button, labelDs);

            Discord_String urlDs = [DiscordSDKBridge discordStringFromString:button2Url];
            Discord_ActivityButton_SetUrl(&button, urlDs);

            Discord_Activity_AddButton(&activity, &button);
            Discord_ActivityButton_Drop(&button);
        }

        // Set activity type
        Discord_Activity_SetType(&activity, (enum Discord_ActivityTypes)activityType);

        // Set application name override
        if (applicationName != nil) {
            Discord_String nameDs = [DiscordSDKBridge discordStringFromString:applicationName];
            Discord_Activity_SetName(&activity, nameDs);
        }

        // Update presence
        Discord_Client_UpdateRichPresence(_client, &activity, NULL, NULL, NULL);

        Discord_Activity_Drop(&activity);

        return YES;

    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"DiscordPresenceKit"
                                        code:2002
                                    userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Unknown error"}];
        }
        return NO;
    }
}

- (void)runCallbacks {
    // Don't call if we know it crashes
    if (g_callbacksCrashed.load()) {
        return;
    }

    // Skip if not initialized
    if (!_isInitialized || _client == NULL) {
        return;
    }

    // Check if the client is actually connected before calling RunCallbacks
    // Discord_RunCallbacks will crash if the client isn't in a ready state
    enum Discord_Client_Status status = Discord_Client_GetStatus(_client);

    // Only call RunCallbacks if we're connected or ready
    // Skip during connecting/disconnecting/disconnected states
    if (status != Discord_Client_Status_Connected &&
        status != Discord_Client_Status_Ready) {
        // Not ready yet - skip this callback round
        return;
    }

    // If we've never succeeded before, check the opaque pointer too
    if (!_hasCalledCallbacksSuccessfully) {
        if (_client->opaque == NULL) {
            return;
        }
    }

    // Safe to call RunCallbacks now
    Discord_RunCallbacks();
    _hasCalledCallbacksSuccessfully = YES;
    g_callbacksEverSucceeded.store(true);
}

- (void)shutdown {
    if (_client != NULL) {
        Discord_Client_Drop(_client);
        free(_client);
        _client = NULL;
    }
    _isInitialized = NO;
}

@end
