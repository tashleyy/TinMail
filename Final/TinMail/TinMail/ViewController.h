//
//  ViewController.h
//  TinMail
//
//  Created by Ashley Tjahjadi on 11/22/15.
//  Copyright (c) 2015 Tiffany Tjahjadi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLGmail.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) GTLServiceGmail *service;
@property (nonatomic, strong) UITextView *output;

@end