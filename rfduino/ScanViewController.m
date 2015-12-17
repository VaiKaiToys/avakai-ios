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

#import <QuartzCore/QuartzCore.h>
#import "ScanViewController.h"
#import "RFduinoManager.h"
#import "RFduino.h"
#import "AppViewController.h"
#import <Parse/Parse.h>
#import <AudioToolbox/AudioServices.h>


@interface ScanViewController()
{
    bool editingRow;
    bool loadService;
    bool connected;
}
@end

@implementation ScanViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        UINavigationItem *navItem = [self navigationItem];
        [navItem setTitle:@"Avakais"];
        rfduinoManager = [RFduinoManager sharedRFduinoManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    rfduinoManager.delegate = self;
    
    int numberOfLines = 3;
    self.tableView.rowHeight = (44.0 + (numberOfLines - 1) * 19.0);
    
    /*UIColor *start = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.15];
    UIColor *stop = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.45];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    // gradient.frame = [self.view bounds];
    gradient.frame = CGRectMake(0.0, 0.0, 1024.0, 1024.0);
    gradient.colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)stop.CGColor, nil];
    [self.tableView.layer insertSublayer:gradient atIndex:0];
*/
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[rfduinoManager rfduinos] count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    // if (! cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.numberOfLines = 1;
    RFduino *rfduino = [[rfduinoManager rfduinos] objectAtIndex:[indexPath row]];
    if([rfduino delegate] == self){
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avakai-turk.png"]];
        cell.accessoryView = iv;
        cell.detailTextLabel.text = @"via Bluetooth";
    }else{
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avakai-grey.png"]];
        cell.detailTextLabel.text = @"not connected";

        cell.accessoryView = iv;
    }

    UIView* av = [[UIView alloc] init];
    av.frame = CGRectMake(29.5, 35, 5, 5);
    av.layer.cornerRadius = 3.0;
    av.backgroundColor = [UIColor whiteColor];

    [cell.accessoryView addSubview:av];

    if (rfduino.advertisementData) {
        cell.textLabel.text  = [[NSString alloc] initWithData:rfduino.advertisementData encoding:NSUTF8StringEncoding];
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    RFduino *rfduino = [rfduinoManager.rfduinos objectAtIndex:[indexPath row]];
    return (rfduino.outOfRange ? YES : NO);
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    editingRow = true;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    editingRow = false;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [rfduinoManager.rfduinos removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RFduino *rfduino = [[rfduinoManager rfduinos] objectAtIndex:[indexPath row]];
    NSLog(@"pressed cell");
//    if (! rfduino.outOfRange) {
    if([rfduino delegate] != self){
        [rfduinoManager connectRFduino:rfduino];
    } else {
        uint8_t tx[3] = {  10, 2,  99 };
        NSData *data = [NSData dataWithBytes:(void*)&tx length:3];
        [rfduino send:data];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - RfduinoDiscoveryDelegate methods

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (void)shouldDisplayAlertTitled:(NSString *)title messageBody:(NSString *)body
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:body
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

#endif

- (void)didDiscoverRFduino:(RFduino *)rfduino
{
    NSLog(@"didDiscoverRFduino");
    if (! editingRow) {
        NSLog(@"reloadData");
        [self.tableView reloadData];
    }
}

- (void)didUpdateDiscoveredRFduino:(RFduino *)rfduino
{
    // NSLog(@"didUpdateRFduino");
    if (! editingRow) {
        [self.tableView reloadData];
    }
}

- (void)didConnectRFduino:(RFduino *)rfduino
{
    NSLog(@"didConnectRFduino");
    //[rfduinoManager stopScan];
    //loadService = false;
}

- (void)didLoadServiceRFduino:(RFduino *)rfduino
{
    //    loadService = true;
    [self.tableView reloadData];
    [rfduino setDelegate:self];
    NSLog(@"didLoadServiceRFduino");
}

- (void)didDisconnectRFduino:(RFduino *)rfduino
{
    [rfduino setDelegate: NULL];
    NSLog(@"didDisconnectRFduino");
    [self.tableView reloadData];
}

- (void)didReceive:(NSData *)data
{
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
    NSDictionary *item1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"A new message is waiting for your Avakai.", @"0", @"1", @"", nil]
                                                      forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"content-available", @"sound",nil]];
    [PFPush sendPushDataToQueryInBackground:pushQuery withData: item1];
    NSLog(@"Received Bluetooth data from Avakai");
    //    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    //    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

// Override to support rearranging the table view. - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {}
// Override to support conditional rearranging of the table view. - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{    // Return NO if you do not want the item to be re-orderable.    return YES;}

@end
