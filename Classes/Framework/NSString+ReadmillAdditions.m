/*
 Copyright (c) 2011 Readmill LTD
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "NSString+ReadmillAdditions.h"
#import "NSDateFormatter+ReadmillAdditions.h"

@implementation NSString (ReadmillAdditions)

- (NSString *)urlEncodedString {
	
	CFStringRef str = CFURLCreateStringByAddingPercentEscapes(NULL,
															  (CFStringRef)self,
															  NULL,
															  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
															  kCFStringEncodingUTF8);
	
	NSString *unencodedString = [NSString stringWithString:(NSString *)str];	
	
	CFRelease(str);
	
	return unencodedString;
}

-(NSString *)urlDecodedString {
    
    CFStringRef str = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                              (CFStringRef)self,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8);
    
    NSString *decodedString = [NSString stringWithString:(NSString *)str];
    
    CFRelease(str);
    
    return decodedString;
}

- (NSDate *)dateWithRFC3339Formatting {

    NSDateFormatter *formatter = [NSDateFormatter readmillDateFormatter];
    // Convert the RFC 3339 date time string to an NSDate.
    return [formatter dateFromString:self];
}

@end
