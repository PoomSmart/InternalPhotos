#import <substrate.h>
#import <objc/runtime.h>
#import "../PS.h"

@interface PUAbstractAlbumListViewController : UIViewController
- (UIBarButtonItem *)_internalButtonItem;
@end

/*@interface PUPhotosGridViewController : UIViewController
- (UIBarButtonItem *)_internalButtonItem;
@end*/

@interface PURootSettings
+ (void)presentSettingsController;
@end

static void showInternalSettings()
{
	[%c(PURootSettings) presentSettingsController];
}

static UIImage *internalGearImage()
{
	CGFloat screenScale = [[UIScreen mainScreen] scale];
	NSString *path = nil;
	if (screenScale == 0 || screenScale == 1)
		path = @"/Library/Application Support/InternalPhotos/UIBarButtonItemGear.png";
	else
		path = [NSString stringWithFormat:@"/Library/Application Support/InternalPhotos/UIBarButtonItemGear@%lux.png", (unsigned long)(NSUInteger)screenScale];
	return [[UIImage imageWithContentsOfFile:path] retain];
}

%hook PUAbstractAlbumListViewController

UIBarButtonItem *_btn;

%new
- (UIBarButtonItem *)_internalButtonItem
{
	if (objc_getAssociatedObject(self, &_btn) == nil) {
		UIButton *gear = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
		UIImage *gearImage = internalGearImage();
		[gear setImage:gearImage forState:UIControlStateNormal];
		[gear sizeToFit];
		[gear addTarget:self action:@selector(ip_handleInternalButton:) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithCustomView:gear];
		[gear release];
		objc_setAssociatedObject(self, &_btn, btn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[btn release];
    }
    return objc_getAssociatedObject(self, &_btn);
}

%new
- (void)ip_handleInternalButton:(id)sender
{
	showInternalSettings();
}

- (void)updateNavigationBarAnimated:(BOOL)animated
{
	%orig;
	UINavigationItem *navigationItem = [self.navigationItem retain];
	NSMutableArray *rightButtons = [[navigationItem.rightBarButtonItems retain] mutableCopy];
	if (rightButtons == nil)
		return;
	UIBarButtonItem *internalButton = [[self _internalButtonItem] retain];
	if ([rightButtons containsObject:internalButton])
		return;
	[rightButtons addObject:internalButton];
	[navigationItem setRightBarButtonItems:rightButtons animated:animated];
	[navigationItem release];
	[rightButtons release];
	[internalButton release];
}

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	[pool drain];
}