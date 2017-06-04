#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Foundation/NSData.h>
#include <Foundation/NSObjCRuntime.h>
#include <QuickLook/QuickLook.h>

int HEADER_LENGTH = 4;

UInt8 header_bytes[4] = {
    0x00,
    0x50,
    0x42,
    0x50
};

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
    NSLog(@"PSP Previewer executed on '%@'", url);
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    
    CFDictionaryRef properties = NULL;
    if (!QLThumbnailRequestIsCancelled(thumbnail)) {
        CGImageRef imageRef = NULL;
        
        NSData *imageData = [NSData dataWithContentsOfURL: (__bridge NSURL * _Nonnull)(url)];
        
        if ([[imageData subdataWithRange:(NSRange){0,4}] isEqualToData:[NSData dataWithBytes:header_bytes length:4]]) {
        
        NSLog(@"valid PSP header found!");

        //imageRef = CGImageSourceCreateWithData(dictData, NULL);

        QLThumbnailRequestSetImage(thumbnail, imageRef, properties);

        //CFRelease(dictData);
        CGImageRelease(imageRef);
        }
    } else {
        QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
    }

    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
