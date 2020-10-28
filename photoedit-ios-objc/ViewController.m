//
//  ViewController.m
//  photoedit-ios-objc
//
//  Created by Luka Mijatovic on 05/02/2020.
//  Copyright © 2020 DeepAR. All rights reserved.
//

#import "ViewController.h"
#import <DeepAR/ARView.h>

@interface ViewController () <ARViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    CMSampleBufferRef _sampleBuffer;
}

@property (nonatomic, strong) ARView* arview;
@property (nonatomic, strong) DeepAR* deepAR;
@property (nonatomic, strong) UIImage* photo;
@property (nonatomic, assign) BOOL searchingForFace;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchingForFace = NO;
}

- (IBAction)loadPhotoTapped:(id)sender {
    self.searchingForFace = NO;
    if(self.arview){
        [self.arview removeFromSuperview];
        [self.arview shutdown];
        self.arview = nil;
        self.photo = nil;
    }
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage* photo = info[UIImagePickerControllerOriginalImage];
    if (photo) {
        self.photo = [self resizePhoto:photo outputSize:CGSizeMake(720, 1280)];
        [self processPhoto];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIImage*)resizePhoto:(UIImage*)image outputSize:(CGSize)outputSize {
    CGRect imageRect = CGRectZero;
    
    if (outputSize.height/outputSize.width < image.size.height/image.size.width) {
        CGFloat height = outputSize.width * image.size.height/image.size.width;
        imageRect = CGRectMake(0, (outputSize.height-height)/2.0, outputSize.width, height);
    } else {
        CGFloat width = outputSize.height * image.size.width/image.size.height;
        imageRect = CGRectMake((outputSize.width-width)/2.0, 0, width, outputSize.height);
    }

    UIGraphicsBeginImageContext(outputSize);
    [image drawInRect:imageRect];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (void)processPhoto {
    self.arview = [[ARView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.arview setLicenseKey:@"04363a986dfffbeb1938fdcb3e8ae4566bd6f7e5bcf3c5abb79a0006fec67e7b137c86221c1a9f61"];
    self.arview.delegate = self;
    [self.view insertSubview:self.arview atIndex:0];
    [self.arview initialize];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              };
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                                          CGImageGetHeight(image), kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status!=kCVReturnSuccess) {
        NSLog(@"Operation failed");
    }
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image), CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0 );
    CGContextConcatCTM(context, flipHorizontal);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

- (void)didFinishPreparingForVideoRecording {
    
}

- (void)didStartVideoRecording {
    
}

- (void)didFinishVideoRecording:(NSString*)videoFilePath {
    
}

- (void)recordingFailedWithError:(NSError*)error {
    
}

- (void)didTakeScreenshot:(UIImage*)screenshot {
//    UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil);
//    [self.arview removeFromSuperview];
//    [self.arview shutdown];
//    self.arview = nil;
//    self.photo = nil;
}

- (void)didInitialize {
    if (self.photo) {
        CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:self.photo.CGImage];
        CMTime presentationTime = CMTimeMake(10, 1000000);
        CMSampleTimingInfo timingInfo;
        timingInfo.duration = kCMTimeInvalid;
        timingInfo.decodeTimeStamp = kCMTimeInvalid;
        timingInfo.presentationTimeStamp = presentationTime;
        
        CMVideoFormatDescriptionRef videoInfo = NULL;
        CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);

        _sampleBuffer = NULL;
        CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timingInfo, &_sampleBuffer);
        self.searchingForFace = YES;
        
        [self.arview switchEffectWithSlot:@"mask" path:[[NSBundle mainBundle] pathForResource:@"aviators" ofType:@""]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [NSTimer scheduledTimerWithTimeInterval:0.5
                    target:self
                    selector:@selector(targetMethod)
                    userInfo:nil
                    repeats:YES];
        });

    }
}

-(void) targetMethod  {
    NSLog(@"Calling enqueue frame");
    [self enqueueFrame:_sampleBuffer];
}

- (void)enqueueFrame:(CMSampleBufferRef) sampleBuffer{
    if (!self.searchingForFace){
        return;
    }
    [self.arview enqueueCameraFrame:sampleBuffer mirror:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self enqueueFrame:sampleBuffer];
    });
}

- (void)faceVisiblityDidChange:(BOOL)faceVisible {
    //[self.arview takeScreenshot];
    self.searchingForFace = NO;
}

- (void)didSwitchEffect:(NSString *)slot {
    
}

@end
