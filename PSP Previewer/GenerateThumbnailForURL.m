#include <CoreServices/CoreServices.h>
#include <Foundation/NSData.h>
#include <QuickLook/QuickLook.h>

int PBP_MAGIC_LENGTH = 4;
UInt8 PBP_MAGIC[4] = {
    0x00,
    0x50,
    0x42,
    0x50
};

uint16_t TwoLittleNSDataBytesToBigUInt16(NSData* data) {
    uint8_t *uint8data = (uint8_t *)[data bytes];
    return ((uint16_t)uint8data[1] << 8) + (uint16_t)uint8data[0];
}

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
    NSLog(@"PSP Previewer executed on '%@'", url);
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();

    CFURLRef fallbackThumbnailURL = CFBundleCopyResourceURL(mainBundle, CFSTR("ICON0"), CFSTR("PNG"), NULL);

    CFDictionaryRef properties = NULL;
    if (!QLThumbnailRequestIsCancelled(thumbnail)) {
        NSData *imageData = [NSData dataWithContentsOfURL: (__bridge NSURL * _Nonnull)(url)];
        
        if ([
             [imageData subdataWithRange:(NSRange){0, PBP_MAGIC_LENGTH}]
                isEqualToData:[NSData dataWithBytes:PBP_MAGIC length:PBP_MAGIC_LENGTH]
        ]) {
            NSLog(@"valid PSP magic header found! reading offsets...");

            uint16_t icon0_offset = TwoLittleNSDataBytesToBigUInt16([imageData subdataWithRange:(NSRange){0x0c, 2}]);
            uint16_t icon0_offset_end = TwoLittleNSDataBytesToBigUInt16([imageData subdataWithRange:(NSRange){0x10, 2}]);
            
            uint16_t icon0_length = icon0_offset_end - icon0_offset;
            
            if (icon0_length > 0) {
                NSLog(@"ICON0 is at %hu, and %hu bytes long!", icon0_offset, icon0_length);

                NSData *icon0 = [imageData subdataWithRange:(NSRange){icon0_offset, icon0_length}];

                QLThumbnailRequestSetImageWithData(thumbnail, (__bridge CFDataRef)icon0, properties);
            
                return noErr;
            } else {
                NSLog(@"ICON0 is missing!");
                QLThumbnailRequestSetImageAtURL(thumbnail, fallbackThumbnailURL, properties);
                return noErr;
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
