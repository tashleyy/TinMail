//
//  MainView.h
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//  Based on https://github.com/cwRichardKim/TinderSimpleSwipeCards
//

#import <UIKit/UIKit.h>
#import "GmailService.h"

@protocol MainViewDelegate <NSObject>

- (void) cardSwipedLeft: (UIView*)card;
- (void) cardSwipedRight: (UIView*)card;
- (void) cardDoubleTapped: (UIView*)card;

@end

@interface MainView : UIView

@property (weak, nonatomic) id <MainViewDelegate> delegate;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSString *identifier;

- (void) reset;
- (void) swipeLeft;
- (void) swipeRight;

@end
