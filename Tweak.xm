#import <substrate.h>
#import <UIKit/UIImage+Private.h>
#import "../PS.h"

extern "C" NSBundle *PLPhotoLibraryFrameworkBundle();
NSString *const presentDebugNotificationKey = @"com.PS.InternalPhotos.presentDebugNotificationKey";

static void showInternalSettings() {
    if (isiOS71Up)
        [%c(PURootSettings) presentSettingsController];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:presentDebugNotificationKey object:nil userInfo:nil];
}

static UIImage *internalGearImage() {
    return [[UIImage imageNamed:@"UIBarButtonItemGear.png" inBundle:PLPhotoLibraryFrameworkBundle()] retain];
}

UIBarButtonItem *_btn;

%hook ALBUMCONTROLLER

%new
- (UIBarButtonItem *)_internalButtonItem {
    if (objc_getAssociatedObject(self, &_btn) == nil) {
        UIButton *gear = [[UIButton alloc] initWithFrame:CGRectZero];
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
- (void)ip_handleInternalButton: (id)sender {
    showInternalSettings();
}

- (void)updateNavigationBarAnimated:(BOOL)animated {
    %orig;
    UINavigationItem *navigationItem = [[self navigationItem] retain];
    NSArray *buttonItems = isiOS8Up ? navigationItem.leftBarButtonItems : navigationItem.rightBarButtonItems;
    NSMutableArray *buttons = [[buttonItems retain] mutableCopy];
    if (buttons == nil)
        return;
    UIBarButtonItem *internalButton = [[self _internalButtonItem] retain];
    if ([buttons containsObject:internalButton])
        return;
    [buttons addObject:internalButton];
    if (isiOS8Up)
        [navigationItem setLeftBarButtonItems:buttons animated:animated];
    else
        [navigationItem setRightBarButtonItems:buttons animated:animated];
    [navigationItem release];
    [buttons release];
    [internalButton release];
}

%end

BOOL overrideInternal = NO;

extern "C" BOOL CPIsInternalDevice();
%hookf(BOOL, CPIsInternalDevice) {
    return overrideInternal ? YES : %orig;
}

%hook NSUserDefaults

- (BOOL)boolForKey: (NSString *)key {
    return [key isEqualToString:@"PUEnableDoubleTapSettings"] ? YES : %orig;
}

%end

%hook PLPhotosApplication

- (void)applicationDidFinishLaunching: (id)arg1 {
    if (isiOS70)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_statusBarDoubleTap:) name:presentDebugNotificationKey object:nil];
    overrideInternal = YES;
    %orig;
    overrideInternal = NO;
}

%end

%ctor {
    %init(ALBUMCONTROLLER = isiOS8Up ? objc_getClass("PUAlbumListViewController") : objc_getClass("PUAbstractAlbumListViewController"));
}
