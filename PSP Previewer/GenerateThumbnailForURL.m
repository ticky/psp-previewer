#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    CFDictionaryRef properties = NULL;
    if (!QLThumbnailRequestIsCancelled(thumbnail)) {
        CGImageRef imageRef = NULL;
        CFStringRef filepath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        
        
        
        // 2. render it
        if (imageRef != NULL) {
            QLThumbnailRequestSetImage(thumbnail, imageRef, properties);
            CGImageRelease(imageRef);
        } else {
            QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
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
