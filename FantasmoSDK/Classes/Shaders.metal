//
//  Shaders.metal
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 27.01.22.
//

#include <metal_stdlib>
using namespace metal;


kernel void convert_ycbcr_to_rgb(texture2d<float, access::read> y_texture [[texture(0)]],
                                 texture2d<float, access::read> cbcr_texture [[texture(1)]],
                                 texture2d<float, access::write> rgb_texture [[texture(2)]],
                                 device const float& gamma [[ buffer(0) ]],
                                 uint2 gid [[thread_position_in_grid]])
{
    float3 color_offset = float3(-(16.0 / 255.0), -0.5, -0.5);
    float3x3 color_transform = float3x3(float3(1.164,  1.164, 1.164),
                                        float3(0.000, -0.392, 2.017),
                                        float3(1.596, -0.813, 0.000));
    
    float y = y_texture.read(gid).r;
    
    uint2 cbcr_coord = uint2(gid.x / 2, gid.y / 2); // half because ARKit uses 4:2:0 chroma subsampling
    float2 cbcr = cbcr_texture.read(cbcr_coord).rg;
    
    float3 ycbcr = float3(y, cbcr);
    float3 rgb = color_transform * (ycbcr + color_offset);
    
    if (gamma != 1.0) {
        rgb = pow(rgb, gamma);
    }
    
    rgb_texture.write(float4(float3(rgb), 1.0), gid);
}

kernel void calculate_gamma_correction(device const uint32_t* histogram_data [[ buffer(0) ]],
                                       device const int& number_of_bins [[ buffer(1) ]],
                                       device const float& target_brightness [[ buffer(2) ]],
                                       device float& gamma_result [[ buffer(3) ]])
{
    // calculate the average brightness from the histogram data
    int pixel_count = 0;
    float total_brightness = 0.0;
    for (int i = 0; i < number_of_bins; i++) {
        pixel_count += histogram_data[i];
        total_brightness += (float)i / (float)number_of_bins * (float)histogram_data[i];
    }
    float average_brightness = total_brightness / (float)pixel_count;
    
    if (average_brightness >= target_brightness) {
        // image is bright enough, no correction needed
        gamma_result = 1.0;
        return;
    }
    
    // prepare a bisection loop to find the appropriate gamma
    const int max_iterations = 50;
    int iterations = 0;
    float gamma = 1.0;
    float mod = 0.5;
    
    // create upper and lower target brightness ranges +/- 1%
    const float target_brightness_upper = target_brightness + target_brightness / 100.0;
    const float target_brightness_lower = target_brightness - target_brightness / 100.0;
    
    // bisection loop
    while (true) {
        
        // add/subtract the current modifier
        if (average_brightness < target_brightness) {
            gamma -= mod;
        } else {
            gamma += mod;
        }
        
        // calculate the new average brightness with current gamma
        total_brightness = 0.0;
        for (int i = 0; i < number_of_bins; i++) {
            float bin_edge_value = (float)i / (float)number_of_bins;
            total_brightness += pow(bin_edge_value, gamma) * (float)histogram_data[i];
        }
        average_brightness = total_brightness / (float)pixel_count;
        
        // check if the new average brightness is in the target range
        if (average_brightness >= target_brightness_lower && average_brightness <= target_brightness_upper) {
            // success
            break;
        }
        
        iterations += 1;
        if (iterations >= max_iterations) {
            // failed to reached target brightness after max_iterations, abort
            gamma = 1.0;
            break;
        }
        
        // halve our modifier for the next iteration
        mod /= 2.0;
    }
    
    gamma_result = gamma;
}
