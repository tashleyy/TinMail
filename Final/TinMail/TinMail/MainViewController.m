//
//  MainViewController.m
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//  Based on https://github.com/cwRichardKim/TinderSimpleSwipeCards
//

#import "MainViewController.h"
#import "GmailService.h"
#import "SWRevealViewController.h"
#import <Firebase/Firebase.h>

static NSString *const kKeychainItemName = @"Gmail API";
static NSString *const kClientID = @"159696253233-pk0eg3irijum60l32055b4glj6gbdoeq.apps.googleusercontent.com";
static NSString *const kClientSecret = @"6Yt11eomNzT5CXNnpUU1XZri";
static const int MAX_BUFFER_SIZE = 2;

@interface MainViewController ()

@property (strong, nonatomic) GmailService *gmail;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;
@property (strong, nonatomic) NSMutableArray *allCards;
@property (strong, nonatomic) NSMutableArray *loadedCards;
@property (strong, nonatomic) NSArray *actions;
@property (strong, nonatomic) MainView *lastCard;
@property (nonatomic) NSUInteger undoIndex;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (strong, nonatomic) NSString *nextPageToken;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.menuButton setTarget: self.revealViewController];
        [self.menuButton setAction: @selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    // Do any additional setup after loading the view.
    
    void(^None)(NSString *iden) = [ ^(NSString *iden) {} copy];
    void(^MarkRead)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesModify];
        query.identifier = iden;
        query.addLabelIds = nil;
        query.removeLabelIds = @[@"UNREAD"];
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to modify message: error=%@", [error description]);
            }
        }];
    } copy];
    void(^MarkUnread)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesModify];
        query.identifier = iden;
        query.addLabelIds = @[@"UNREAD"];
        query.removeLabelIds = nil;
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to modify message: error=%@", [error description]);
            }
        }];
    } copy];
    void (^Trash)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesTrash];
        query.identifier = iden;
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to trash message: error=%@", [error description]);
            }
        }];
    } copy];
    void (^Untrash)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesUntrash];
        query.identifier = iden;
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to untrash message: error=%@", [error description]);
            }
        }];
    } copy];
    void (^Star)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesModify];
        query.identifier = iden;
        query.addLabelIds = @[@"STARRED"];
        query.removeLabelIds = nil;
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to modify message: error=%@", [error description]);
            }
        }];
    } copy];
    void (^Unstar)(NSString *iden) = [ ^(NSString *iden) {
        GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesModify];
        query.identifier = iden;
        query.addLabelIds = nil;
        query.removeLabelIds = @[@"STARRED"];
        [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                if (error.code == 403) [self presentViewController:[self createAuthController] animated:YES completion:nil];
                NSLog(@"Failed to modify message: error=%@", [error description]);
            }
        }];
    } copy];
    self.actions = [NSArray arrayWithObjects:None, MarkRead, MarkUnread, Trash, Star, Unstar, None, MarkUnread, MarkRead, Untrash, Unstar, Star, nil];
    
    self.gmail = [GmailService sharedService];
    self.allCards = [NSMutableArray array];
    self.loadedCards = [NSMutableArray array];
    self.undoIndex = 0;
    self.undoButton.enabled = false;
    self.nextPageToken = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!self.gmail.service.authorizer.canAuthorize) {
            // Not yet authorized, request authorization by pushing the login UI onto the UI stack.
            [self presentViewController:[self createAuthController] animated:YES completion:nil];
        } else {
            [self retrieveSettings];
            [self fetchLabels];
        }
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.gmail.numLabels > 0) [self fetchMessages];
}


// Creates the auth controller for authorizing access to Gmail API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeGmailModify, nil];
    GTMOAuth2ViewControllerTouch *authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:[scopes componentsJoinedByString:@" "] clientID:kClientID clientSecret:kClientSecret keychainItemName:kKeychainItemName completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        if (error != nil) {
            [self showAlert:@"Authentication Error" message:error.localizedDescription];
            self.gmail.service.authorizer = nil;
        }
        else {
            self.gmail.service.authorizer = auth;
            [self dismissViewControllerAnimated:YES completion:nil];
            [self retrieveSettings];
            [self fetchLabels];
        }
    }];
    return authController;
}

- (void)retrieveSettings {
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersGetProfile];
    [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        GTLGmailProfile *profile = object;
        NSString *email = profile.emailAddress;
        NSArray *tokens = [email componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@."]];
        Firebase *root = [[Firebase alloc] initWithUrl:@"https://tinmail.firebaseio.com/users"];
        Firebase *user = [root childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", tokens[2], tokens[1], tokens[0]]];
        [user observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            if (snapshot.value != [NSNull null]) {
                NSNumber *left = snapshot.value[@"left"];
                NSNumber *right = snapshot.value[@"right"];
                self.gmail.leftIndex = [left unsignedIntegerValue];
                self.gmail.rightIndex = [right unsignedIntegerValue];
            }
        }];
    }];
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)addCard:(NSString*)str withID:(NSString*)iden {
    MainView *mainView = [[MainView alloc] initWithFrame:CGRectMake(0, 0, self.cardView.bounds.size.width, self.cardView.bounds.size.height)];
    [mainView.webView loadHTMLString:str baseURL:nil];
    mainView.identifier = iden;
    mainView.delegate = self;
    
    if (self.loadedCards.count < MAX_BUFFER_SIZE) {
        [self.loadedCards addObject:mainView];
        if (self.loadedCards.count == 1) {
            [self.cardView addSubview:[self.loadedCards objectAtIndex:0]];
        } else {
            [self.cardView insertSubview:self.loadedCards[self.loadedCards.count-1] belowSubview:self.loadedCards[self.loadedCards.count-2]];
        }
    } else {
        [self.allCards addObject:mainView];
    }
}

- (void)fetchLabels {
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersLabelsList];
    [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            GTLGmailListLabelsResponse *labelsResponse = object;
            if (labelsResponse.labels.count > 0) {
                [self.gmail clearLabels];
                for (GTLGmailLabel *label in labelsResponse.labels) {
                    if (![label.name isEqualToString:@"DRAFT"] && ![label.name isEqualToString:@"TRASH"] && (label.name.length <= 9 || ![[label.name substringToIndex:9] isEqualToString:@"CATEGORY_"])) {
                        [self.gmail addLabel:label];
                    }
                }
                [self fetchMessages];
            } else {
                [self.gmail clearLabels];
                [self showAlert:@"No Labels" message:@"No labels found."];
            }
        } else {
            [self.gmail clearLabels];
            if (error.code == 400) {
                [self presentViewController:[self createAuthController] animated:YES completion:nil];
            } else {
                [self showAlert:@"Error" message:error.localizedDescription];
            }
        }
    }];
}

- (void)fetchMessages {
    self.allCards = [NSMutableArray array];
    self.loadedCards = [NSMutableArray array];
    self.title = self.gmail.currLabel.name.capitalizedString;
    GTLQueryGmail *query1 = [GTLQueryGmail queryForUsersMessagesList];
    query1.q = [NSString stringWithFormat:@"label:%@", self.gmail.currLabel.name.lowercaseString];
    query1.maxResults = 30;
    [self.gmail.service executeQuery:query1 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            GTLGmailListMessagesResponse *response = object;
            self.nextPageToken = response.nextPageToken;
            if (response.messages.count > 0) {
                for (GTLGmailMessage *message in response.messages) {
                    GTLQueryGmail *query2 = [GTLQueryGmail queryForUsersMessagesGet];
                    query2.identifier = message.identifier;
                    [self.gmail.service executeQuery:query2 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (error == nil) {
                            GTLGmailMessage *msg = object;
                            [self parsePart:msg.payload withID:msg.identifier];
                        } else {
                            NSLog(@"Error.");
                            [self showAlert:@"Error" message:error.localizedDescription];
                        }
                    }];
                }
            } else {
                NSLog(@"No messages.");
                [self showAlert:@"No Messages" message:@"No more messages with this label."];
            }
        } else {
            NSLog(@"Error.");
            if (error.code == 403) {
                [self presentViewController:[self createAuthController] animated:YES completion:nil];
            } else {
                [self showAlert:@"Error" message:error.localizedDescription];
            }
        }
    }];
}

- (void)fetchMore {
    GTLQueryGmail *query1 = [GTLQueryGmail queryForUsersMessagesList];
    query1.q = [NSString stringWithFormat:@"label:%@", self.gmail.currLabel.name.lowercaseString];
    query1.pageToken = self.nextPageToken;
    self.nextPageToken = nil;
    query1.maxResults = 30;
    [self.gmail.service executeQuery:query1 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            GTLGmailListMessagesResponse *response = object;
            self.nextPageToken = response.nextPageToken;
            if (response.messages.count > 0) {
                for (GTLGmailMessage *message in response.messages) {
                    GTLQueryGmail *query2 = [GTLQueryGmail queryForUsersMessagesGet];
                    query2.identifier = message.identifier;
                    [self.gmail.service executeQuery:query2 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (error == nil) {
                            GTLGmailMessage *msg = object;
                            [self parsePart:msg.payload withID:msg.identifier];
                        } else {
                            NSLog(@"Error.");
                            [self showAlert:@"Error" message:error.localizedDescription];
                        }
                    }];
                }
            } else {
                NSLog(@"No messages.");
                [self showAlert:@"No Messages" message:@"No more messages with this label."];
            }
        } else {
            NSLog(@"Error.");
            if (error.code == 403) {
                [self presentViewController:[self createAuthController] animated:YES completion:nil];
            } else {
                [self showAlert:@"Error" message:error.localizedDescription];
            }
        }
    }];
}

- (void)parsePart:(GTLGmailMessagePart*)part withID:(NSString *)iden {
    if (part.parts != nil) {
        for (GTLGmailMessagePart *p in part.parts) {
            [self parsePart:p withID:iden];
        }
    } else if (part.body.data != nil && ![part.mimeType isEqualToString:@"text/plain"]) {
        [self parseBodyData:part.body withID:iden];
    } else if (part.body.attachmentId != nil){
        [self parseBodyAttach:part.body withID:iden];
    } else if (![part.mimeType isEqualToString:@"text/plain"]) {
        NSLog(@"Cannot parse part: %@", part);
    }
}

- (void)parseBodyData:(GTLGmailMessagePartBody*)body withID:(NSString*)iden {
    NSString *data = body.data;
    NSString *s = [self readBodyData:data];
    [self addCard:s withID:iden];
}

- (void)parseBodyAttach:(GTLGmailMessagePartBody*)body withID:(NSString*)iden {
    GTLQueryGmail *query3 = [GTLQueryGmail queryForUsersMessagesAttachmentsGet];
    query3.identifier = body.attachmentId;
    query3.messageId = iden;
    [self.gmail.service executeQuery:query3 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            GTLGmailMessagePartBody *b = object;
            if (b.data != nil) {
                [self parseBodyData:b withID:iden];
            } else if (b.attachmentId != nil) {
                [self parseBodyAttach:b withID:iden];
            }
        } else {
            NSLog(@"Error.");
            [self showAlert:@"Error" message:error.localizedDescription];
        }
    }];
}

- (NSString*)readBodyData:(NSString*) data {
    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"-"];
    data = [[data componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @"+"];
    doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    data = [[data componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @"/"];
    NSData *htmlData = [[NSData alloc] initWithBase64EncodedString:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *s = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    return s;
}

- (IBAction)leftButtonTapped:(id)sender {
    [self.loadedCards.firstObject swipeLeft];
}

- (IBAction)rightButtonTapped:(id)sender {
    [self.loadedCards.firstObject swipeRight];
}

- (IBAction)undoButtonTapped:(id)sender {
    void (^action)(NSString *iden) = self.actions[self.undoIndex];
    
    [self.lastCard reset];
    [self.loadedCards insertObject:self.lastCard atIndex:0];
    [((MainView*)self.loadedCards.lastObject) removeFromSuperview];
    [self.loadedCards removeObjectAtIndex:self.loadedCards.count-1];
    
    if (self.loadedCards.count > 1) {
        [self.cardView insertSubview:self.lastCard aboveSubview:self.loadedCards[1]];
    } else {
        [self.cardView addSubview:self.lastCard];
    }
    
    action(self.lastCard.identifier);
    self.undoButton.enabled = false;
}

- (void)cardSwipedLeft:(UIView *)card {
    void (^action)(NSString *iden) = self.actions[self.gmail.leftIndex];
    self.lastCard = (MainView*)card;
    
    [self.loadedCards removeObjectAtIndex:0];
    if (self.allCards.count > 0) {
        [self.loadedCards addObject:self.allCards[0]];
        [self.allCards removeObjectAtIndex:0];
        if (self.loadedCards.count > 1) {
            [self.cardView insertSubview:self.loadedCards[MAX_BUFFER_SIZE-1] belowSubview:self.loadedCards[MAX_BUFFER_SIZE-2]];
        } else {
            [self.cardView addSubview:self.loadedCards[MAX_BUFFER_SIZE-1]];
        }
    }
    if (self.nextPageToken != nil && self.allCards.count < 10) {
        [self fetchMore];
    } else if (self.loadedCards.count == 0) {
        [self showAlert:@"No More Messages" message:@"No more messages with this label."];
    }
    action(self.lastCard.identifier);
    self.undoIndex = self.gmail.leftIndex + NUM_ACTIONS;
    self.undoButton.enabled = true;
}

- (void)cardSwipedRight:(UIView *)card {
    void (^action)(NSString *iden) = self.actions[self.gmail.rightIndex];
    self.lastCard = (MainView*)card;
    
    [self.loadedCards removeObjectAtIndex:0];
    if (self.allCards.count > 0) {
        [self.loadedCards addObject:self.allCards[0]];
        [self.allCards removeObjectAtIndex:0];
        if (self.loadedCards.count > 1) {
            [self.cardView insertSubview:self.loadedCards[MAX_BUFFER_SIZE-1] belowSubview:self.loadedCards[MAX_BUFFER_SIZE-2]];
        } else {
            [self.cardView addSubview:self.loadedCards[MAX_BUFFER_SIZE-1]];
        }
    }
    if (self.nextPageToken != nil && self.allCards.count < 10) {
        [self fetchMore];
    } else if (self.loadedCards.count == 0) {
        [self showAlert:@"No More Messages" message:@"No more messages with this label."];
    }
    action(self.lastCard.identifier);
    self.undoIndex = self.gmail.rightIndex + NUM_ACTIONS;
    self.undoButton.enabled = true;
}

- (void)cardDoubleTapped:(UIView *)card {
    [self.loadedCards removeObjectAtIndex:0];
    if (self.allCards.count > 0) {
        [self.loadedCards addObject:self.allCards[0]];
        [self.allCards removeObjectAtIndex:0];
        if (self.loadedCards.count > 1) {
            [self.cardView insertSubview:self.loadedCards[MAX_BUFFER_SIZE-1] belowSubview:self.loadedCards[MAX_BUFFER_SIZE-2]];
        } else {
            [self.cardView addSubview:self.loadedCards[MAX_BUFFER_SIZE-1]];
        }
    }
    if (self.nextPageToken != nil && self.allCards.count < 10) {
        [self fetchMore];
    } else if (self.loadedCards.count == 0) {
        [self showAlert:@"No More Messages" message:@"No more messages with this label."];
    }
    self.lastCard = (MainView*)card;
    self.undoIndex = NUM_ACTIONS;
    self.undoButton.enabled = true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
