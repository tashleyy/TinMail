//
//  MainView.m
//  
//
//  Created by Ashley Tjahjadi on 11/23/15.
//  Based on https://github.com/cwRichardKim/TinderSimpleSwipeCards
//

#import "MainView.h"

// Transformation constants obtained from Richard Kim's code
static const int ACTION_MARGIN = 120; // Action is valid past this margin
static const int SCALE_STRENGTH = 4; // Speed card shrinks. Higher = slower
static const float SCALE_MAX = .93; // How much card shrinks. Higher = less
static const int ROTATION_MAX = 1; // Max rotation in radians. Higher = rotates longer
static const int ROTATION_STRENGTH = 320; // Strength of rotation. Higher = weaker
static const float ROTATION_ANGLE = M_PI/8; // Angle of rotation. Higher = stronger

@interface MainView ()

@property (nonatomic) CGPoint originalPoint;
@property (nonatomic) CGFloat xFromCenter;
@property (nonatomic) CGFloat yFromCenter;
@property (strong, nonatomic) GmailService *gmail;

@end

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
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doNothing:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(beingDragged:)];
        [self addGestureRecognizer:pan];
        
        self.backgroundColor = [UIColor whiteColor];
        self.originalPoint = self.center;
    }
    return self;
}

- (void)doNothing:(UITapGestureRecognizer*)doubleTap {
    [self removeFromSuperview];
    [self.delegate cardDoubleTapped:self];
}

// Transformation method obtained from Richard Kim's code
- (void)beingDragged:(UIPanGestureRecognizer*)pan {
    // Pan coordinates
    self.xFromCenter = [pan translationInView:self].x;
    self.yFromCenter = [pan translationInView:self].y;
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.originalPoint = self.center;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat rotationStrength = MIN(self.xFromCenter / ROTATION_STRENGTH, ROTATION_MAX);
            CGFloat rotationAngle = (CGFloat) (ROTATION_ANGLE * rotationStrength);
            CGFloat scale = MAX(1 - fabs(rotationStrength) / SCALE_STRENGTH, SCALE_MAX);
            self.center = CGPointMake(self.originalPoint.x + self.xFromCenter, self.originalPoint.y + self.yFromCenter);
            CGAffineTransform transform = CGAffineTransformMakeRotation(rotationAngle);
            CGAffineTransform scaleTransform = CGAffineTransformScale(transform, scale, scale);
            self.transform = scaleTransform;
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self afterSwipeAction];
            break;
        }
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (void)afterSwipeAction {
    if (self.xFromCenter > ACTION_MARGIN) {
        CGPoint finishPoint = CGPointMake(500, 2*self.yFromCenter + self.originalPoint.y);
        [UIView animateWithDuration:0.3 animations:^{
            self.center = finishPoint;
        } completion:^(BOOL complete) {
            [self removeFromSuperview];
        }];
        [self.delegate cardSwipedRight:self];
    } else if (self.xFromCenter < -ACTION_MARGIN) {
        CGPoint finishPoint = CGPointMake(-500, 2*self.yFromCenter + self.originalPoint.y);
        [UIView animateWithDuration:0.3 animations:^{
            self.center = finishPoint;
        } completion:^(BOOL complete) {
            [self removeFromSuperview];
        }];
        [self.delegate cardSwipedLeft:self];
    } else {
        [UIView animateWithDuration:0.3 animations: ^{
            self.center = self.originalPoint;
            self.transform = CGAffineTransformMakeRotation(0);
        }];
    }
}

- (void)reset {
    [UIView animateWithDuration:0.3 animations: ^{
        self.center = self.originalPoint;
        self.transform = CGAffineTransformMakeRotation(0);
    }];
}

- (void)swipeLeft {
    CGPoint finishPoint = CGPointMake(-600, self.center.y);
    [UIView animateWithDuration:0.3 animations:^{
        self.center = finishPoint;
        self.transform = CGAffineTransformMakeRotation(-1);
    } completion:^(BOOL complete) {
        [self removeFromSuperview];
    }];
    
    [self.delegate cardSwipedLeft:self];
}

- (void)swipeRight {
    CGPoint finishPoint = CGPointMake(600, self.center.y);
    [UIView animateWithDuration:0.3 animations:^{
        self.center = finishPoint;
        self.transform = CGAffineTransformMakeRotation(1);
    } completion:^(BOOL complete) {
        [self removeFromSuperview];
    }];
    
    [self.delegate cardSwipedRight:self];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
