//
//  MainView.m
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//
//

#import "MainView.h"

@implementation MainView

- (id)initWithFrame: (CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 4;
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.2;
        self.layer.shadowOffset = CGSizeMake(1, 1);
        
        self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(20, 20, self.frame.size.width-40, self.frame.size.height-40)];
        [self.webView setBackgroundColor:[UIColor clearColor]];
        self.webView.scalesPageToFit = YES;
        [self addSubview:self.webView];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
