//
//  Shaders.metal
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 27.01.22.
//

#include <metal_stdlib>
using namespace metal;

kernel void compute_gamma_correction(device const uint32_t* histogram_data,
                                     device const int* number_of_bins,
                                     device const float* target_brightness,
                                     device float* gamma_correction_result)
{
    // calculate the average brightness from the histogram data
    int pixel_count = 0;
    float total_brightness = 0.0;
    for (int i = 0; i < *number_of_bins; i++) {
        pixel_count += histogram_data[i];
        total_brightness += (float)i / (float)*number_of_bins * (float)histogram_data[i];
    }
    float average_brightness = total_brightness / (float)pixel_count;
    
    if (average_brightness >= *target_brightness) {
        // image is bright enough, no correction needed
        *gamma_correction_result = 1.0;
        return;
    }
    
    // prepare a bisection loop to find the appropriate gamma correction
    const int max_iterations = 50;
    int iterations = 0;
    float gamma_correction = 1.0;
    float mod = 0.5;
    
    // create upper and lower target brightness ranges +/- 1%
    const float target_brightness_upper = *target_brightness + *target_brightness / 100.0;
    const float target_brightness_lower = *target_brightness - *target_brightness / 100.0;
    
    // bisection loop
    while (true) {
        
        // add/subtract the current modifier
        if (average_brightness < *target_brightness) {
            gamma_correction -= mod;
        } else {
            gamma_correction += mod;
        }
        
        // calculate the new average brightness with current gamma
        total_brightness = 0.0;
        for (int i = 0; i < *number_of_bins; i++) {
            float bin_edge_value = (float)i / (float)*number_of_bins;
            total_brightness += pow(bin_edge_value, gamma_correction) * (float)histogram_data[i];
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
            gamma_correction = 1.0;
            break;
        }
        
        // halve our modifier for the next iteration
        mod /= 2.0;
    }
    
    *gamma_correction_result = gamma_correction;
}

/*
 /*
 
 func getAverageBrightness(_ histogramBufferContents: UnsafeMutablePointer<UInt32>, numberOfBins: Int, adjustedGamma: Float? = nil) -> Float {
     var pixelCount: UInt32 = 0
     var totalBrightness: Float = 0.0
     for i in 0...numberOfBins {
         pixelCount += histogramBufferContents[i]
         var binEdgeValue = Float(i) / Float(numberOfBins)
         if let adjustedGamma = adjustedGamma {
             binEdgeValue = pow(binEdgeValue, adjustedGamma)
         }
         totalBrightness += Float(histogramBufferContents[i]) * binEdgeValue
     }
     return totalBrightness / Float(pixelCount)
 }
 
 let histogram = imageHistogramBuffer.contents().assumingMemoryBound(to: UInt32.self)
 
 var averageBrightness = getAverageBrightness(histogram, numberOfBins: numberOfBins)
 let targetBrightness: Float = 0.15
 if averageBrightness > targetBrightness {
     print("image is bright enough")
     return originalFrame
 }
 
 // Create an acceptable target brightness range +/- 1 percent
 let targetBrightnessRange = (targetBrightness - targetBrightness / 100.0)...(targetBrightness + targetBrightness / 100.0)
 var gamma: Float = 1.0
 var step: Float = 0.5
 var iterations: Int = 0
 while true {
     // Add/subtract the current step modifier to get our next gamma adjustment
     if averageBrightness < targetBrightness {
         gamma -= step
     } else {
         gamma += step
     }
     // Halve our step modifier
     step /= 2.0
     // Calculate the new average brightness with the gamma adjustment
     averageBrightness = getAverageBrightness(histogram, numberOfBins: numberOfBins, adjustedGamma: gamma)
     // And Check if new average brightness is in range
     if targetBrightnessRange.contains(averageBrightness) {
         print("adjust gamma by: \(gamma) - new average brightness: \(averageBrightness) - iterations: \(iterations)")
         break
     }
     iterations += 1
 }
 */
