//
//  SSLPlaceViewController.h
//  SSLLunchPool
//
//  Created by sam_lai on 4/23/16.
//  Copyright © 2016 Sam Lai. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GMSPlace;
@protocol SSLPlaceViewControllerDelegate <NSObject>

@optional
- (void)controller:(UIViewController *)controller didSelectPlace:(GMSPlace *)place;

@end

@interface SSLPlaceViewController : UITableViewController
@property (nonatomic, weak) id <SSLPlaceViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *places;
@end
