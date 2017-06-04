#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Foundation/NSObjCRuntime.h>
#include <QuickLook/QuickLook.h>

int HEADER_LENGTH = 4;
UInt8 VALID_HEADER[4] = {
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
    NSURL *URL = (__bridge NSURL *)url;
    NSLog(@"PSP Previewer executed on '%@'\n", URL);
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    
    CFDictionaryRef properties = NULL;
    if (!QLThumbnailRequestIsCancelled(thumbnail)) {
        CGImageRef imageRef = NULL;
        
        CFReadStreamRef fileStream = CFReadStreamCreateWithFile(NULL, url);
        
        if (CFReadStreamOpen(fileStream)) {
            //CFDataRef dictData = (CFDataRef)CFDataCreateWithBytesNoCopy(NULL, bytes, length, kCFAllocatorNull);

            UInt8 header[4];
            CFReadStreamRead(fileStream, header, 4);
            
            if (header == VALID_HEADER) {
    
                NSLog(@"valid PSP header found\n");

                //imageRef = CGImageSourceCreateWithData(dictData, NULL);

                QLThumbnailRequestSetImage(thumbnail, imageRef, properties);

                //CFRelease(dictData);
                CGImageRelease(imageRef);
            }
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
