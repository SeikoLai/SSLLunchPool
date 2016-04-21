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

#define ARC4RANDOM_MAX      0x100000000

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImagePickerController *_imagePickerController;
    UIPopoverController *_popoverController;
    NSMutableArray *_restaurants;
    __weak IBOutlet UIButton *startButton;
    __weak IBOutlet UIButton *stopButton;
    __weak IBOutlet UIButton *addButton;
    BOOL _starting;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)add:(id)sender;

@end

@implementation ViewController

- (void)loadView
{
    [super loadView];
    
    startButton = [self circleButtonFromButton:startButton];
    stopButton = [self circleButtonFromButton:stopButton];
    
    NSArray *imageNames = @[@"Brunch", @"koera", @"McDonald's", @"MosBurger", @"noodles", @"stirFries", @"TiMAMA"];
    
    _restaurants = [NSMutableArray new];
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        [self popCamera];
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        NSLog(@"%@", @"Camera access not determined. Ask for permission.");
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             if(granted)
             {
                 NSLog(@"Granted access to %@", AVMediaTypeVideo);
                 [self popCamera];
             }
             else
             {
                 NSLog(@"Not granted access to %@", AVMediaTypeVideo);
                 [self camDenied];
             }
         }];
    }
    else if (authStatus == AVAuthorizationStatusRestricted)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else
    {
        [self camDenied];
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
    if (!image) {
        NSString *imagePath = [self imagePathFromDirectoriesInDomains];
        image = [UIImage imageWithContentsOfFile:imagePath];
    }
    self.imageView.image = image;
}

- (void)popCamera
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:_imagePickerController animated:YES completion:NULL];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"No Camera Available." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        alert = nil;
    }
}

- (void)camDenied
{
    NSLog(@"%@", @"Denied camera access");
    
    NSString *alertText;
    NSString *alertButton;
    
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings)
    {
        alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Touch Privacy.\n\n3. Turn the Camera on.\n\n4. Open this app and try again.";
        
        alertButton = @"Go";
    }
    else
    {
        alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Close this app.\n\n2. Open the Settings app.\n\n3. Scroll to the bottom and select this app in the list.\n\n4. Touch Privacy.\n\n5. Turn the Camera on.\n\n6. Open this app and try again.";
        
        alertButton = @"OK";
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:alertText
                          delegate:self
                          cancelButtonTitle:alertButton
                          otherButtonTitles:nil];
    alert.tag = 3491832;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 3491832)
    {
        BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
        if (canOpenSettings)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void) imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self saveOriginalImage:originalImage];
            SSLRestaurant *restaurant = [SSLRestaurant new];
            restaurant.title = [[self imagePathFromDirectoriesInDomains] lastPathComponent];
            restaurant.image = [[self imagePathFromDirectoriesInDomains] lastPathComponent];
            
            [_restaurants addObject:restaurant];
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            [_imagePickerController dismissViewControllerAnimated:YES completion:^{
                self.imageView.image = originalImage;
            }];
        });
    }
}

- (void)saveOriginalImage:(UIImage *)originalImage
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *str = @"sample.png";
    NSString *imagePath = [path stringByAppendingPathComponent:str];
    NSData *imagedata = UIImagePNGRepresentation(originalImage);
    [imagedata writeToFile:imagePath atomically:YES];
}

- (NSString *)imagePathFromDirectoriesInDomains
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *str = @"sample.png";
    return [path stringByAppendingPathComponent:str];
}

@end
