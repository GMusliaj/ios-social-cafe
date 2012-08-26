/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "PhotoViewController.h"

@interface PhotoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@end

@implementation PhotoViewController
@synthesize photoImageView;
@synthesize image = _image;
@synthesize confirmCallback = confirmCallback;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.photoImageView setImage:self.image];
}

- (void)viewDidUnload
{
    [self setPhotoImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.photoImageView = nil;
    self.image = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Action methods
- (IBAction)cancelButtonAction:(id)sender {
    if (self.confirmCallback) {
        self.confirmCallback(self, false);
    }
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)confirmButtonAction:(id)sender {
    if (self.confirmCallback) {
        self.confirmCallback(self, true);
    }
    [self.navigationController popViewControllerAnimated:true];
}

@end
