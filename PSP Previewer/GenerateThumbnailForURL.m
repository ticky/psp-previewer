#include <CoreServices/CoreServices.h>
#include <Foundation/NSData.h>
#include <QuickLook/QuickLook.h>

#define PBP_OFFSET_LENGTH 4
#define PBP_MAGIC_LENGTH 4
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

  CFDictionaryRef properties = NULL;

  // If we have permission, press on!
  if (!QLThumbnailRequestIsCancelled(thumbnail)) {
    // Load the file in question
    NSData *imageData = [NSData dataWithContentsOfURL: (__bridge NSURL * _Nonnull)(url)];
        
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

        QLThumbnailRequestSetImageWithData(thumbnail, (__bridge CFDataRef)icon0, properties);
      } else {
        NSLog(@"ICON0 is missing!");
        // Pass QuickLook a fallback image
        QLThumbnailRequestSetImageAtURL(thumbnail, fallbackThumbnailURL, properties);
      }
    }
  } else {
    NSLog(@"no PSP magic header found!");
    QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
  }

  return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail) {
  // Implement only if supported
}
