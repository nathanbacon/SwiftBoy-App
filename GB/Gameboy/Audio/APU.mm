//
//  APU.m
//  GB
//
//  Created by Nathan Gelman on 9/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

#include "Gb_Apu.h"
#include "Multi_Buffer.h"

#import "APU.h"
#import <Foundation/Foundation.h>

@implementation APU
Gb_Apu *gb_apu;
Stereo_Buffer *stereo_buffer;
NSMutableData* out_buf;
//@synthesize gb_apu = _gb_apu;
//@synthesize stereo_buffer = _stereo_buffer;
//@synthesize out_buf = _out_buf;

- (id)init {
    self = [super init];
    if (self) {
        gb_apu = new Gb_Apu();
        stereo_buffer = new Stereo_Buffer();
        
        stereo_buffer->set_sample_rate(44100);
        stereo_buffer->clock_rate( 4194304 );
        gb_apu->set_output(stereo_buffer->center(), stereo_buffer->left(), stereo_buffer->right());
        
        out_buf = [NSMutableData dataWithLength:4096];
    }
    return self;
}

- (void)dealloc {
    delete gb_apu;
    delete stereo_buffer;
}

- (void) write_register:(uint32_t)time :(uint32_t)addr :(uint32_t)data {
    gb_apu->write_register(time, addr, data);
}

- (int) read_register:(uint32_t)time :(uint32_t)addr {
    return gb_apu->read_register(time, addr);
}

- (long)end_frame:(uint32_t)time {
    const int out_size = 4096;
    
    gb_apu->end_frame(time);
    stereo_buffer->end_frame(time);
    
    if ( stereo_buffer->samples_avail() >= out_size ) {
        short* a = (short*)[out_buf mutableBytes];
        
        auto count = stereo_buffer->read_samples(a, out_size);
        
        return count;
    }
    
    return 0;
}

@end

