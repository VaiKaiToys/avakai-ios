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

#import "AppDelegate.h"
#import <Parse/Parse.h>

#import "ScanViewController.h"
#import "RFduinoManager.h"
#import "RFduino.h"

@interface AppDelegate()
{
    RFduinoManager *rfduinoManager;
    bool wasScanning;
    ScanViewController *scanViewController;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"NFkmPbOSWfkrZqof8E1D2dAnv0lyZb8EnrakcbrT"
                  clientKey:@"0V9mnHCepkmaXVvRaWnsqkocTKyJGVhdYO22npqY"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    rfduinoManager = RFduinoManager.sharedRFduinoManager;
    
    ScanViewController *viewController = [[ScanViewController alloc] init];
    scanViewController = viewController;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window setRootViewController:navController];
    
    navController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    wasScanning = false;
    
    if (rfduinoManager.isScanning) {
        wasScanning = true;
        [rfduinoManager stopScan];
    }
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)pushData
    fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSLog(@"Received remote push notification from Parse");

    NSString *type = [pushData objectForKey:@"type"];
    NSString *avakaiId = [pushData objectForKey:@"avakaiId"];

    if([@"AvakaiMessage" isEqualToString: type]){
        for(RFduino *rfduino in rfduinoManager.rfduinos)
        {
            if([avakaiId isEqualToString: @""] || [avakaiId isEqualToString: [[NSString alloc] initWithData:rfduino.advertisementData encoding:NSUTF8StringEncoding]])
            {
                uint8_t tx[3] = { 5, 3, 99 };
                NSData *data = [NSData dataWithBytes:(void*)&tx length:3];
                [rfduino send:data];
            }
        }

        for(UITableViewCell *cell in [[scanViewController tableView] visibleCells])
        {
            if([avakaiId isEqualToString: @""] || [avakaiId isEqualToString: cell.textLabel.text])
            {
                cell.detailTextLabel.text = @"Received a message.";
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                    //cell.detailTextLabel.text = @"via Bluetooth";
                });
            }
        }
    }else if([@"AvakaiConnected" isEqualToString: type]){
        // scanViewController push into an array
        //        viewController.connectedAvakais
        [scanViewController->remoteAvakais addObject: avakaiId];
        [[scanViewController tableView] reloadData];
    }else if([@"AvakaiDisconnected" isEqualToString: type]){
        [scanViewController->remoteAvakais removeObject: avakaiId];
        [[scanViewController tableView] reloadData];

    }else{
        NSLog(@"Unknown Message Type: %@", type);
    }

    if (handler) {
        handler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {}
- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (wasScanning) {
        [rfduinoManager startScan];
        wasScanning = false;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {}

@end
