//
//  MainViewController.m
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//
//

#import "MainViewController.h"
#import "GmailService.h"
#import "SWRevealViewController.h"

static NSString *const kKeychainItemName = @"Gmail API";
static NSString *const kClientID = @"159696253233-pk0eg3irijum60l32055b4glj6gbdoeq.apps.googleusercontent.com";
static NSString *const kClientSecret = @"6Yt11eomNzT5CXNnpUU1XZri";
static const int MAX_BUFFER_SIZE = 2; //%%% max number of cards loaded at any given time, must be greater than 1
static const float CARD_HEIGHT = 550; //%%% height of the draggable card
static const float CARD_WIDTH = 350; //%%% width of the draggable card

@interface MainViewController ()

@property (nonatomic, strong) GmailService *gmail;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;
@property (strong, nonatomic) NSMutableArray *allCards;
@property (strong, nonatomic) NSMutableArray *loadedCards;
@property (nonatomic) NSUInteger cardsLoadedIndex;

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
    self.gmail = [GmailService sharedService];
    self.allCards = [NSMutableArray array];
    self.loadedCards = [NSMutableArray array];
    self.cardsLoadedIndex = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!self.gmail.service.authorizer.canAuthorize) {
            // Not yet authorized, request authorization by pushing the login UI onto the UI stack.
            [self presentViewController:[self createAuthController] animated:YES completion:nil];
        } else {
            [self fetchLabels];
        }
    });
    if (self.gmail.numLabels > 0) [self fetchMessages];
}

// When the view appears, ensure that the Gmail API service is authorized, and perform API calls.
- (void)viewDidAppear:(BOOL)animated {
}


// Creates the auth controller for authorizing access to Gmail API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeGmailReadonly, nil];
    GTMOAuth2ViewControllerTouch *authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:[scopes componentsJoinedByString:@" "] clientID:kClientID clientSecret:kClientSecret keychainItemName:kKeychainItemName completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        if (error != nil) {
            [self showAlert:@"Authentication Error" message:error.localizedDescription];
            self.gmail.service.authorizer = nil;
        }
        else {
            self.gmail.service.authorizer = auth;
            [self dismissViewControllerAnimated:YES completion:nil];
            [self fetchLabels];
        }
    }];
    return authController;
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)addCard:(NSString*)str withID:(NSString*)iden {
    MainView *mainView = [[MainView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - CARD_WIDTH)/2, (self.view.frame.size.height - CARD_HEIGHT)/2 - 15, CARD_WIDTH, CARD_HEIGHT)];
    [mainView.webView loadHTMLString:str baseURL:nil];
    mainView.delegate = self;
    mainView.identifier = iden;
    [self.allCards addObject:mainView];
    
    if (self.loadedCards.count < MAX_BUFFER_SIZE) {
        [self.loadedCards addObject:mainView];
        if (self.loadedCards.count == 1) {
            [self.view addSubview:[self.loadedCards objectAtIndex:0]];
        } else {
            [self.view insertSubview:self.loadedCards[self.loadedCards.count-1] aboveSubview:self.loadedCards[self.loadedCards.count-2]];
        }
        self.cardsLoadedIndex++;
    }
}

-(void)cardSwipedLeft:(UIView *)card {
}

-(void)cardSwipedRight:(UIView *)card {
}

- (void)fetchLabels {
    NSLog(@"Getting labels...");
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
                NSLog(@"No labels.");
            }
        } else {
            [self.gmail clearLabels];
            NSLog(@"Error.");
        }
    }];
}

- (void)fetchMessages {
    NSLog(@"Getting messages...");
    self.allCards = [NSMutableArray array];
    self.loadedCards = [NSMutableArray array];
    self.title = self.gmail.currLabel.name.capitalizedString;
    GTLQueryGmail *query1 = [GTLQueryGmail queryForUsersMessagesList];
    query1.q = [NSString stringWithFormat:@"label:%@", self.gmail.currLabel.name.lowercaseString];
    [self.gmail.service executeQuery:query1 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            GTLGmailListMessagesResponse *response = object;
            if (response.messages.count > 0) {
                for (GTLGmailMessage *message in response.messages) {
                    GTLQueryGmail *query2 = [GTLQueryGmail queryForUsersMessagesGet];
                    query2.identifier = message.identifier;
                    [self.gmail.service executeQuery:query2 completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (error == nil) {
                            GTLGmailMessage *msg = object;
                            if (msg.payload.parts != nil) {
                                if (((GTLGmailMessagePart*)msg.payload.parts.lastObject).body.data != nil) {
                                    NSString *data = ((GTLGmailMessagePart*)msg.payload.parts.lastObject).body.data;
                                    NSString *s = [self readBodyData:data];
                                    [self addCard:s withID:msg.identifier];
                                }
                            } else if (message.payload.body.data != nil) {
                                NSString *data = message.payload.body.data;
                                NSString *s = [self readBodyData:data];
                                [self addCard:s withID:msg.identifier];
                            }
                        } else {
                            [self showAlert:@"Error" message:error.localizedDescription];
                        }
                    }];
                }
            } else {
                [self showAlert:@"No Messages" message:@"No more messages with this label."];
                NSLog(@"No messages.");
            }
        } else {
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
