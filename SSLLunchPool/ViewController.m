//
//  ViewController.m
//  SSLLunchPool
//
//  Created by sam_lai on 4/13/16.
//  Copyright © 2016 Sam Lai. All rights reserved.
//

#import "ViewController.h"
// Model
#import "SSLRestaurant.h"
#import <AVFoundation/AVFoundation.h>
#import "SSLPlaceViewController.h"
// View
#import "SSLToast.h"

@import GoogleMaps;

#define ARC4RANDOM_MAX      0x100000000

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, SSLPlaceViewControllerDelegate>
{
    UIImagePickerController *_imagePickerController;
    UIPopoverController *_popoverController;
    NSMutableArray *_restaurants;
    __weak IBOutlet UIButton *startButton;
    __weak IBOutlet UIButton *stopButton;
    __weak IBOutlet UIButton *addButton;
    BOOL _starting;
    NSArray *_places;
    NSArray *_photos;
    UIActivityIndicatorView *_activityIndicatorView;
}
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)add:(id)sender;

@end

@implementation ViewController{
    GMSPlacesClient *_placesClient;
}

- (void)loadView
{
    [super loadView];
    
    startButton = [self circleButtonFromButton:startButton];
    stopButton = [self circleButtonFromButton:stopButton];
    
    NSArray *imageNames = @[@"Brunch", @"koera", @"McDonald's", @"MosBurger", @"noodles", @"stirFries", @"TiMAMA"];
    
    _restaurants = [NSMutableArray new];
    _places = [NSArray array];
    _photos = [NSArray array];
    
    for (NSString *imageName in imageNames) {
        if (imageName.length) {
            SSLRestaurant *restaurant = [SSLRestaurant new];
            restaurant.title = imageName;
            restaurant.image = imageName;
            [_restaurants addObject:restaurant];
        }
    }
    
    self.imageView.animationImages = [self animationImagesFromArray:_restaurants];
    self.imageView.animationDuration = ((double)arc4random() / ARC4RANDOM_MAX);
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_places.count == 0) {
        [self fetchPlaceWithCompletion:^(NSArray *places) {
            _places = places;
            _photos = [self restaurantPhotosFromRestaurantPlaceLikehoods:_places];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _placesClient = [[GMSPlacesClient alloc] init];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.center = CGPointMake(CGRectGetMidX([[UIScreen mainScreen] bounds]), CGRectGetMidY([[UIScreen mainScreen] bounds]));
    _activityIndicatorView.hidesWhenStopped = YES;
    [_activityIndicatorView stopAnimating];
    [self.view addSubview:_activityIndicatorView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)start:(id)sender {
    addButton.hidden = YES;
    [self.imageView startAnimating];
    _starting = YES;
}

- (IBAction)stop:(id)sender {
    [self.imageView stopAnimating];
    if (_starting) {
        _starting = NO;
        [self choose];
    }
    addButton.hidden = NO;
}

- (IBAction)add:(id)sender {
    if (_places.count) {
        [_activityIndicatorView stopAnimating];
        SSLPlaceViewController *placeViewController = [[SSLPlaceViewController alloc] init];
        placeViewController.places = _places;
        placeViewController.delegate = self;
        [self presentViewController:placeViewController animated:YES completion:^{
            
        }];
    }
    else {
        [_activityIndicatorView startAnimating];
        [self fetchPlaceWithCompletion:^(NSArray *places) {
            _places = places;
            _photos = [self restaurantPhotosFromRestaurantPlaceLikehoods:_places];
            [self add:nil];
        }];
    }
}

- (UIButton *)circleButtonFromButton:(UIButton *)button
{
    UIButton *circleButton = button;
    CGRect buttonFrame = circleButton.frame;
    CGPoint center = CGPointMake(buttonFrame.size.width*0.5f, buttonFrame.size.height*0.5f);
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath addArcWithCenter:center radius:50 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    
    CAShapeLayer *progressLayer = [[CAShapeLayer alloc] init];
    [progressLayer setPath:bezierPath.CGPath];
    [progressLayer setStrokeColor:[UIColor whiteColor].CGColor];
    [progressLayer setFillColor:[UIColor clearColor].CGColor];
    [progressLayer setLineWidth:5.0f];
    
    [circleButton.layer addSublayer:progressLayer];
    
    return circleButton;
}

- (NSArray *)animationImagesFromArray:(NSArray *)array
{
    NSMutableArray *images = [NSMutableArray new];
    for (id obj in array) {
        if ([obj isKindOfClass:[SSLRestaurant class]]) {
            SSLRestaurant *restaurant = obj;
            UIImage *image = [UIImage imageNamed:restaurant.image];
            if (image) {
                [images addObject:image];
            }
        }
    }
    return [images copy];
}

- (void)choose
{
    int randomNumber = 1 + rand() % (_restaurants.count-1);
    SSLRestaurant *restaurant = _restaurants[randomNumber];
    UIImage *image = [UIImage imageNamed:restaurant.image];
    self.imageView.image = image;
}

#pragma mark - <SSLPlaceViewControllerDelegate>
- (void)controller:(UIViewController *)controller didSelectPlace:(GMSPlace *)place
{
    if ([self conformsToProtocol:@protocol(SSLPlaceViewControllerDelegate) ]) {
        self.nameLabel.text = place.name;
        self.addressLabel.text = place.formattedAddress;
    }
}

- (void)fetchPlaceWithCompletion:(void(^)(NSArray *places))completion
{
    [_placesClient currentPlaceWithCallback:^(GMSPlaceLikelihoodList * _Nullable likelihoodList, NSError * _Nullable error) {
        if (error != nil) {
            NSString *errorMessage = error.localizedDescription;
            NSLog(@"%s, error: %@", __FUNCTION__, errorMessage);
            [self toastWithMessage:errorMessage withInterval:3.0];
            return;
        }
        
        if (likelihoodList != nil) {
            if (completion) {
                NSArray *restaurants = [self restaurantPlaceLikehoodsFromPlaceLikelihoods:[likelihoodList likelihoods]];
                completion(restaurants);
            }
        }
    }];
}

- (NSArray *)restaurantPlaceLikehoodsFromPlaceLikelihoods:(NSArray *)placeLikelihoods
{
    NSMutableArray *restaurants = [NSMutableArray array];
    
    for (GMSPlaceLikelihood *placeLikehood in placeLikelihoods) {
    
        for (NSString *type in placeLikehood.place.types) {
            if ([type isEqualToString:@"restaurant"]) {
                [restaurants addObject:placeLikehood];
            }
        }
    }
    
    return [restaurants copy];
}

- (void)fetchPlacePhotoWithCompletion:(void(^)(NSArray *photos))completion
{

}

- (NSArray *)restaurantPhotosFromRestaurantPlaceLikehoods:(NSArray *)restaurantPlaceLikehoods
{
    __block NSMutableArray *restaurantPhotos = [NSMutableArray array];

    for (GMSPlaceLikelihood *placeLikehood in restaurantPlaceLikehoods) {
        
        [self lookUpPhotosForPlaceID:placeLikehood.place.placeID withCompletion:^(GMSPlacePhotoMetadataList * _Nullable photos, NSError * _Nullable error) {
            if (error != nil) {
                NSString *errorMessage = error.localizedDescription;
                NSLog(@"%s, error: %@", __FUNCTION__, errorMessage);
                [self toastWithMessage:errorMessage withInterval:3.0];
                return;
            }
            if (photos) {
                NSArray *results = photos.results;
                for (GMSPlacePhotoMetadata *result in results) {
                    NSLog(@"%@", result.attributions.string);

                    [self loadPlacePhotoFromPlacePhotoMetadata:result withCompletion:^(UIImage * _Nullable photo, NSError * _Nullable error) {
                        if (error != nil) {
                            NSString *errorMessage = error.localizedDescription;
                            NSLog(@"%s, error: %@", __FUNCTION__, errorMessage);
                            [self toastWithMessage:errorMessage withInterval:3.0];
                            return;
                        }
                        if (photo) {
                            [restaurantPhotos addObject:photo];
                        }
 
                    }];

                }
            }

        }];
    }
    
    return [restaurantPhotos copy];
}

- (void)loadPlacePhotoFromPlacePhotoMetadata:(nonnull GMSPlacePhotoMetadata *)placePhotoMetadata withCompletion:(void(^)(UIImage * _Nullable photo, NSError * _Nullable error))completion
{
    [_placesClient loadPlacePhoto:placePhotoMetadata callback:^(UIImage * _Nullable photo, NSError * _Nullable error) {
        if (completion) {
            completion(photo, error);
        }
    }];
}

- (void)lookUpPhotosForPlaceID:(nonnull NSString *)placeID withCompletion:(void(^)(GMSPlacePhotoMetadataList * _Nullable photos, NSError * _Nullable error))completion
{
    [_placesClient lookUpPhotosForPlaceID:placeID callback:^(GMSPlacePhotoMetadataList * _Nullable photos, NSError * _Nullable error) {
        if (completion) {
            completion(photos, error);
        }
    }];

}

- (void)toastWithMessage:(NSString *)message withInterval:(NSTimeInterval)interval
{
    addButton.hidden = !addButton.hidden;
    
    SSLToast *toast = [SSLToast loadViewWithMessage:message];
    [self.imageView addSubview:toast];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast removeFromSuperview];
        addButton.hidden = !addButton.hidden;
        [_activityIndicatorView stopAnimating];
    });
}

@end
