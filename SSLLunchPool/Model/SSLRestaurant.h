//
//  SSLRestaurant.h
//  SSLLunchPool
//
//  Created by sam_lai on 4/13/16.
//  Copyright © 2016 Sam Lai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SSLRestaurant : NSObject
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double latitude;
@end
