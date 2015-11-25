//
//  MainView.h
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//
//

#import <UIKit/UIKit.h>

@protocol MainViewDelegate <NSObject>

- (void) cardSwipedLeft: (UIView*)card;
- (void) cardSwipedRight: (UIView*)card;

@end

@interface MainView : UIView

@property (weak, nonatomic) id <MainViewDelegate> delegate;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSString *identifier;

@end
