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

@interface GmailService : NSObject

@property (nonatomic, strong) GTLServiceGmail *service;
@property (nonatomic) NSUInteger currIndex;

+ (instancetype) sharedService;
- (NSUInteger) numLabels;
- (GTLGmailLabel*) labelAtIndex: (NSUInteger)index;
- (void) addLabel: (GTLGmailLabel*)label;
- (void) clearLabels;
- (GTLGmailLabel*) currLabel;

@end
