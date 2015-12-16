/*
 Copyright (c) 2013 OpenSourceRF.com.  All right reserved.

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>

#import "AppViewController.h"
#import "UIImage+Extras.h"

#import <AudioToolbox/AudioServices.h>

@implementation AppViewController

@synthesize rfduino;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIButton *backButton = [UIButton buttonWithType:101];  // left-pointing shape
        [backButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(disconnect:) forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [[self navigationItem] setLeftBarButtonItem:backItem];

        [[self navigationItem] setTitle:@"Avakai"];
    }
    return self;
}

- (void)manualLayout
{
    CGRect rect = [[UIScreen mainScreen] bounds];

            colorWheel.frame = CGRectMake(35,20,250,250);

            colorSwatch.frame = CGRectMake(20,304,280,16);

            rLabel.frame = CGRectMake(20,330,21,21);
            gLabel.frame = CGRectMake(20,368,21,21);
            bLabel.frame = CGRectMake(20,406,21,21);

            rSlider.frame = CGRectMake(47,331,202,23);
            gSlider.frame = CGRectMake(47,369,202,23);
            bSlider.frame = CGRectMake(47,407,202,23);

            rValue.frame = CGRectMake(255,327,45,30);
            gValue.frame = CGRectMake(255,365,45,30);
            bValue.frame = CGRectMake(255,403,45,30);

    if (colorWheel.frame.size.width != colorWheel.image.size.width) {
        UIImage *image1 = [UIImage imageNamed:@"colorWheel1.png"];
        UIImage *image2 = [image1 imageByScalingProportionallyToSize:colorWheel.frame.size];
        [colorWheel setImage:image2];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.

    [rfduino setDelegate:self];

    // delegate needed so UITextField textFieldShouldReturn can dismiss the keyboard when the return key is pressed
    rValue.delegate = self;
    gValue.delegate = self;
    bValue.delegate = self;

    UIColor *start = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0];
    UIColor *stop = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    //gradient.frame = [self.view bounds];
    gradient.frame = CGRectMake(0, 0, 1024, 1024);
    gradient.colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)stop.CGColor, nil];
    [self.view.layer insertSublayer:gradient atIndex:0];

    [self manualLayout];


}

- (void)didReceive:(NSData *)data
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

    // Create our Installation query
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];


    NSDictionary *item1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", @"0", @"1", @"", nil]
                                                      forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"content-available", @"sound",nil]];

    //    [PFPush sendPushMessageToQueryInBackground:pushQuery                                   withMessage:@"Hello from your little Avakai!"];

    [PFPush sendPushDataToQueryInBackground:pushQuery withData: item1];
    NSLog(@"Received data from Avakai");
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self manualLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)disconnect:(id)sender
{
    NSLog(@"disconnect pressed");

    [rfduino disconnect];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch* touch = [touches anyObject];
	CGPoint point = [touch locationInView:colorWheel];
    if (CGRectContainsPoint(colorWheel.frame, point)) {
        UIColor *color = [colorWheel.image pixelColorAt:point];
        [self pickedColor:color];
    }
}

- (void)setColor
{

    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];

    [colorSwatch setHighlighted:YES];
    [colorSwatch setTintColor:color];

    uint8_t tx[3] = { red * 255, green * 255, blue * 255 };
    NSData *data = [NSData dataWithBytes:(void*)&tx length:3];

    [rfduino send:data];
}

- (void)pickedColor:(UIColor*)color
{

    const CGFloat *components = CGColorGetComponents([color CGColor]);

    red = components[0];
    green = components[1];
    blue = components[2];

    rSlider.value = red;
    gSlider.value = green;
    bSlider.value = blue;

    rValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(red * 255)];
    gValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(green * 255)];
    bValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(blue * 255)];

    [self setColor];
}

- (IBAction)rSliderChanged:(id)sender
{
    red = [rSlider value];
    rValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(red * 255)];
    [self setColor];
}

- (IBAction)gSliderChanged:(id)sender
{
    green = [gSlider value];
    gValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(green * 255)];
    [self setColor];
}

- (IBAction)bSliderChanged:(id)sender
{
    blue = [bSlider value];
    bValue.text = [[NSString alloc] initWithFormat:@"%d", (int)(blue * 255)];
    [self setColor];
}

- (IBAction)rEditingDidEnd:(id)sender
{
    red = rValue.text.intValue / 255.0;
    rSlider.value = red;
    [self setColor];
}

- (IBAction)gEditingDidEnd:(id)sender
{
    green = gValue.text.intValue / 255.0;
    gSlider.value = green;
    [self setColor];
}

- (IBAction)bEditingDidEnd:(id)sender
{
    blue = bValue.text.intValue / 255.0;
    bSlider.value = blue;
    [self setColor];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
