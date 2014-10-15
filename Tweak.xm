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

extern "C" NSBundle *PLPhotoLibraryFrameworkBundle();
NSString *const presentDebugNotificationKey = @"com.PS.InternalPhotos.presentDebugNotificationKey";

static void showInternalSettings()
{
	if (isiOS71)
		[%c(PURootSettings) presentSettingsController];
	else if (isiOS70)
		[[NSNotificationCenter defaultCenter] postNotificationName:presentDebugNotificationKey object:nil userInfo:nil];
}

static UIImage *internalGearImage()
{
	return [[UIImage imageNamed:@"UIBarButtonItemGear.png" inBundle:PLPhotoLibraryFrameworkBundle()] retain];
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

BOOL overrideInternal = NO;

extern "C" BOOL CPIsInternalDevice();

MSHook(BOOL, CPIsInternalDevice)
{
	return overrideInternal ? YES : _CPIsInternalDevice();
}

%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key
{
	return [key isEqualToString:@"PUEnableDoubleTapSettings"] ? YES : %orig;
}

%end

%hook PLPhotosApplication

- (void)applicationDidFinishLaunching:(id)arg1
{
	if (isiOS70)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_statusBarDoubleTap:) name:presentDebugNotificationKey object:nil];
	overrideInternal = YES;
	%orig;
	overrideInternal = NO;
}

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	MSHookFunction(CPIsInternalDevice, $CPIsInternalDevice, &_CPIsInternalDevice);
	%init;
	[pool drain];
}