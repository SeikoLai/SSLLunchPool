//
//  SSLToast.m
//  SSLLunchPool
//
//  Created by sam_lai on 4/25/16.
//  Copyright © 2016 Sam Lai. All rights reserved.
//

#import "SSLToast.h"

@implementation SSLToast
+ (instancetype)loadViewWithMessage:(NSString *)message
{
    return [[SSLToast alloc] initWithMessage:message];
}

- (instancetype)initWithMessage:(NSString *)message
{
    self = [super init];
    if (self) {
        CGRect frame = [[UIScreen mainScreen] bounds];
        frame.size.height = 88.0f;
        
        self.frame = frame;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:frame];
        messageLabel.text = message;
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.numberOfLines = 0;
        messageLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:messageLabel];
    }
    return self;
}

@end
