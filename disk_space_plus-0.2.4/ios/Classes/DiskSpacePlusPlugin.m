#import "DiskSpacePlusPlugin.h"
#import <disk_space_plus/disk_space_plus-Swift.h>

@implementation DiskSpacePlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDiskSpacePlusPlugin registerWithRegistrar:registrar];
}
@end
