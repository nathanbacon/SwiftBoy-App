//
//  Objc_Stereo_Buffer.m
//  GB
//
//  Created by Nathan Gelman on 9/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

/*#include "Multi_Buffer.h"

#import <Foundation/Foundation.h>

@interface Stereo_Buffer_Wrapper: NSObject

@end



@implementation Stereo_Buffer_Wrapper
@synthesize stereo_buffer = _stereo_buffer;

- (id)init {
    self = [super init];
    if(self) {
        _stereo_buffer = new Stereo_Buffer();
    }
    return self;
}

- (void)dealloc {
    delete _stereo_buffer;
}

- (void)end_frame:(uint32_t)time {
    self.stereo_buffer->end_frame(time);
}

- (void)set_sample_rate:(uint32_t)rate {
    self.stereo_buffer->set_sample_rate(rate);
}

- (uint64_t)samples_avail {
    return self.stereo_buffer->samples_avail();
}

- (long)read_samples:(short*)output :(long)outputsize {
    return self.stereo_buffer->read_samples(output, outputsize);
}

@end
*/
