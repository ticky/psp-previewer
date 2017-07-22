#include <CoreServices/CoreServices.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSUrl.h>
#include <QuickLook/QuickLook.h>

#define PBP_OFFSET_LENGTH 4
#define PBP_MAGIC_LENGTH 4

// Undocumented ( QuickLook Properties
// Borrowed from https://github.com/Marginal/QLVideo/blob/4d6fdee98f87c13ad9fcbb2a66d473a011ec5db9/qlgenerator/GenerateThumbnailForURL.m
const CFStringRef kQLThumbnailPropertyIconFlavorKey = CFSTR("IconFlavor");

typedef NS_ENUM(NSInteger, QLThumbnailIconFlavor)
{
  kQLThumbnailIconPlainFlavor		= 0,
  kQLThumbnailIconShadowFlavor	= 1,
  kQLThumbnailIconBookFlavor		= 2,
  kQLThumbnailIconMovieFlavor		= 3,
  kQLThumbnailIconAddressFlavor	= 4,
  kQLThumbnailIconImageFlavor		= 5,
  kQLThumbnailIconGlossFlavor		= 6,
  kQLThumbnailIconSlideFlavor		= 7,
  kQLThumbnailIconSquareFlavor	= 8,
  kQLThumbnailIconBorderFlavor	= 9,
  // = 10,
  kQLThumbnailIconCalendarFlavor	= 11,
  kQLThumbnailIconPatternFlavor	= 12,
};

const UInt8 PBP_MAGIC[PBP_MAGIC_LENGTH] = {0x00, 0x50, 0x42, 0x50};

uint32_t FourLittleNSDataBytesToBigUInt32(NSData* data) {
    uint8_t *uint8data = (uint8_t *)[data bytes];
    return ((uint32_t)uint8data[3] << 24) + ((uint32_t)uint8data[2] << 16) + ((uint32_t)uint8data[1] << 8) + (uint32_t)uint8data[0];
}

OSStatus GenerateThumbnailForURL(void *thisInterface,
                                 QLThumbnailRequestRef thumbnail,
                                 CFURLRef url,
                                 CFStringRef contentTypeUTI,
                                 CFDictionaryRef options,
                                 CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

OSStatus GenerateThumbnailForURL(void *thisInterface,
                                 QLThumbnailRequestRef thumbnail,
                                 CFURLRef url,
                                 CFStringRef contentTypeUTI,
                                 CFDictionaryRef options,
                                 CGSize maxSize) {

  NSLog(@"PSP Previewer executed on '%@'", url);
    
  // Get backup thumbnail (default PSP thumbnail image)
  CFBundleRef mainBundle = CFBundleGetMainBundle();
  CFURLRef fallbackThumbnailURL = CFBundleCopyResourceURL(mainBundle, CFSTR("ICON0"), CFSTR("PNG"), NULL);

  NSDictionary *properties = [NSDictionary dictionary];

  // If we have permission, press on!
  if (!QLThumbnailRequestIsCancelled(thumbnail)) {
    // Load the file in question
    NSURL *imageUrl = (__bridge NSURL * _Nonnull)(url);
    NSData *imageData = [NSData dataWithContentsOfMappedFile: imageUrl.path];
    
    properties = @{(__bridge NSString *) kQLThumbnailPropertyIconFlavorKey: @(kQLThumbnailIconShadowFlavor) };
    
    // If the file starts with the PBP magic header, let's look at pulling out some details!
    if ([
      [imageData subdataWithRange:(NSRange){0, PBP_MAGIC_LENGTH}]
        isEqualToData:[NSData dataWithBytes:PBP_MAGIC length:PBP_MAGIC_LENGTH]
    ]) {
      NSLog(@"valid PBP magic header found!");
            
      uint32_t icon0_offset = FourLittleNSDataBytesToBigUInt32(
        [imageData subdataWithRange:(NSRange){0x0c, PBP_OFFSET_LENGTH}]
      );
      uint32_t icon0_offset_end = FourLittleNSDataBytesToBigUInt32(
        [imageData subdataWithRange:(NSRange){0x10, PBP_OFFSET_LENGTH}]
      );
            
      uint32_t icon0_length = icon0_offset_end - icon0_offset;

      if (icon0_length > 0) {
        NSLog(@"ICON0 is at 0x%x, and 0x%x bytes long!", icon0_offset, icon0_length);

        // Read the icon data, and pass it to QuickLook!
        NSData *icon0 = [imageData subdataWithRange:(NSRange){icon0_offset, icon0_length}];

        QLThumbnailRequestSetImageWithData(thumbnail, (__bridge CFDataRef)icon0, (__bridge CFDictionaryRef)properties);
      } else {
        NSLog(@"ICON0 is missing!");
        // Pass QuickLook a fallback image
        QLThumbnailRequestSetImageAtURL(thumbnail, fallbackThumbnailURL, (__bridge CFDictionaryRef)properties);
      }
    }
  } else {
    NSLog(@"no PSP magic header found!");
    QLThumbnailRequestSetImageAtURL(thumbnail, url, (__bridge CFDictionaryRef)properties);
  }

  return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail) {
  // Implement only if supported
}
