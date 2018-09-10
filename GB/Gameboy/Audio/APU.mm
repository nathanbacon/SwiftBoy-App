//
//  APU.m
//  GB
//
//  Created by Nathan Gelman on 9/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

#include "Gb_Apu.h"
#include "Multi_Buffer.h"

#import <Foundation/Foundation.h>



@interface APU: NSObject

@end

@interface APU ()
@property (nonatomic, readwrite, assign) Gb_Apu *gb_apu;
@property (nonatomic, readwrite, assign) Stereo_Buffer *stereo_buffer;
@property (nonatomic, readwrite) NSArray* out_buf;
@end

@implementation APU
@synthesize gb_apu = _gb_apu;
@synthesize stereo_buffer = _stereo_buffer;
@synthesize out_buf = _out_buf;

- (id)init {
    self = [super init];
    if (self) {
        _gb_apu = new Gb_Apu();
        _stereo_buffer = new Stereo_Buffer();
        
        _stereo_buffer->set_sample_rate(44100);
        _stereo_buffer->clock_rate( 4194304 );
        _gb_apu->set_output(_stereo_buffer->center(), _stereo_buffer->left(), _stereo_buffer->right());
        
        _out_buf = [NSMutableArray arrayWithCapacity:4096];
    }
    return self;
}

- (void)dealloc {
    delete _gb_apu;
    delete _stereo_buffer;
}

- (void) write_register:(uint32_t)time :(uint32_t)addr :(int32_t)data {
    _gb_apu->write_register(time, addr, data);
}

- (int) read_register:(uint32_t)time :(uint32_t)addr {
    return _gb_apu->read_register(time, addr);
}

- (void)end_frame:(uint32_t)time {
    const int out_size = 4096;
    blip_sample_t out_buf [out_size];
    
    _gb_apu->end_frame(time);
    _stereo_buffer->end_frame(time);
    
    if ( _stereo_buffer->samples_avail() >= out_size ) {
        auto count = _stereo_buffer->read_samples(out_buf, out_size);
        
    }
}

@end

