//
//  GmailService.h
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//
//

#import <Foundation/Foundation.h>
#import "GmailService.h"
#import "GTLGmail.h"
#import "GTMOAuth2ViewControllerTouch.h"

static const NSUInteger NUM_ACTIONS = 6;

@interface GmailService : NSObject

@property (nonatomic, strong) GTLServiceGmail *service;
@property (nonatomic) NSUInteger currIndex;
@property (nonatomic) NSUInteger leftIndex;
@property (nonatomic) NSUInteger rightIndex;
@property (strong, nonatomic) NSArray *actionNames;

+ (instancetype) sharedService;
- (NSUInteger) numLabels;
- (GTLGmailLabel*) labelAtIndex: (NSUInteger)index;
- (void) addLabel: (GTLGmailLabel*)label;
- (void) clearLabels;
- (GTLGmailLabel*) currLabel;

@end
