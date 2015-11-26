//
//  GmailService.m
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//
//

#import "GmailService.h"

static NSString *const kKeychainItemName = @"Gmail API";
static NSString *const kClientID = @"159696253233-pk0eg3irijum60l32055b4glj6gbdoeq.apps.googleusercontent.com";
static NSString *const kClientSecret = @"6Yt11eomNzT5CXNnpUU1XZri";

@interface GmailService()

@property (strong, nonatomic) NSMutableArray *labels;

@end

@implementation GmailService

- (instancetype)init {
    self = [super init];
    if (self) {
        _service = [[GTLServiceGmail alloc] init];
        _service.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
        _currIndex = 0;
        _leftIndex = 0;
        _rightIndex = 0;
        _labels = [NSMutableArray array];
        _actionNames = [NSArray arrayWithObjects:@"None", @"Mark Read", @"Mark Unread", @"Move to Trash", @"Star", @"Unstar", nil];
    }
    return self;
}

+ (instancetype)sharedService {
    static GmailService *_sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _sharedService = [[self alloc] init]; });
    return _sharedService;
}

- (NSUInteger)numLabels {
    return self.labels.count;
}

- (GTLGmailLabel*)labelAtIndex:(NSUInteger)index {
    return self.labels[index];
}

- (void) addLabel: (GTLGmailLabel*)label {
    [self.labels addObject:label];
}

- (void) clearLabels {
    self.labels = [NSMutableArray array];
}

- (GTLGmailLabel*)currLabel {
    return self.labels[self.currIndex];
}

@end
