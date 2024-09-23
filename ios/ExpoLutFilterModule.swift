import ExpoModulesCore
import Foundation
import UIKit

public class ExpoLutFilterModule: Module {
    var grainOpacity: Double = 0.8
    var grainImage: CIImage? = nil
    // valid blend modes: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
    var grainBlendMode: String = "CIScreenBlendMode"
    var filterMap: [String: FilterColorCube] = [:]
    
    enum InputError: Error {
        case failedToLoadLUT
        case failedToLoadInputImage
        case failedToLoadGrainImage
        case failedToApplyGrain
    }
    enum OutputError: Error {
        case failedToApplyGrain
    }
    
    public func definition() -> ModuleDefinition {
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('ExpoLutFilter')` in JavaScript.
        Name("ExpoLutFilter")
        
        
        // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
        AsyncFunction("setGrainImage") { (grainUri: String) in
            grainImage = loadCIImage(from: grainUri)
            if grainImage == nil {
                throw InputError.failedToLoadGrainImage
            }
        }
        
        Function("setGrainOpacity") { (grainOpacity: Double) in
            self.grainOpacity = grainOpacity
        }
        
        Function("setGrainBlendMode") { (grainBlendMode: String) in
            self.grainBlendMode = grainBlendMode
        }
        
        // Defines a JavaScript function that always returns a Promise and whose native code
        // is by default dispatched on the different thread than the JavaScript runtime runs on.
        AsyncFunction("applyLUT") { (inputImageUri: String, filterId: String, lutUri: String, lutDimension: Int, compression: Double, withGrain: Bool) in
            let lut = loadCGImage(from: lutUri)
            if lut == nil {
                throw InputError.failedToLoadLUT
            }
            let lutImageSource = ImageSource(cgImage: lut!)
            var input = loadCIImage(from: inputImageUri)
            if input == nil {
                throw InputError.failedToLoadInputImage
            }
            if withGrain && grainImage != nil {
                print("applying grain...")
                input = overlayImageWithBlendMode(mainImage: input!, overlayImage: grainImage!, opacity: grainOpacity, blendMode: grainBlendMode)
                print("applied grain!")
            }
            let filter: FilterColorCube
            if let existingFilter = filterMap[filterId]{
                filter = existingFilter
            } else {
                filter = FilterColorCube(identifier: filterId, lutImage: lutImageSource, dimension: lutDimension)
                filterMap[filterId] = filter
            }
            let outputCI = filter.apply(to: input!)
            let outputUri = saveCIImageToCache(outputCI, compressionQuality: CGFloat(compression))
            return outputUri?.absoluteString
        }
    }
    
    func renderCIImageToCGImage(_ ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil) // Create a Core Image context
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    func saveCIImageToCache(_ ciImage: CIImage, compressionQuality: CGFloat = 0.8) -> URL? {
        // Render the CIImage to a CGImage
        guard let cgImage = renderCIImageToCGImage(ciImage) else {
            print("Failed to render CGImage from CIImage")
            return nil
        }
        
        // Convert CGImage to UIImage (optional but simplifies saving)
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert UIImage to JPEG Data with spec ified compression quality
        guard let imageData = uiImage.jpegData(compressionQuality: compressionQuality) else {
            print("Failed to convert UIImage to JPEG data")
            return nil
        }
        
        // Get the cache directory URL
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to get cache directory")
            return nil
        }
        
        // Create a unique file name for the JPEG image
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Write the image data to the cache directory
        do {
            try imageData.write(to: fileURL)
            print("Compressed image saved to cache directory: \(fileURL)")
            return fileURL
        } catch {
            print("Error saving compressed image to cache: \(error)")
            return nil
        }
    }
    
    func loadCGImage(from localURI: String) -> CGImage? {
        guard let url = URL(string: localURI) else {
            print("Invalid URL")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                print("Unable to form UIImage")
                return nil
            }
            
            guard let cgImage = image.cgImage else {
                print("CGImage is nil. This format might not be directly compatible.")
                return nil
            }
            
            return cgImage
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }

    func loadCIImage(from localURI: String) -> CIImage? {
        guard let url = URL(string: localURI) else {
            print("Invalid URL")
            return nil
        }

        // Load the CIImage with orientation metadata applied
        let options = [CIImageOption.applyOrientationProperty: true]
        guard let ciImage = CIImage(contentsOf: url, options: options) else {
            print("Unable to create CIImage from URL")
            return nil
        }

        return ciImage
    }
    
    func adjustOpacity(of image: CIImage, opacity: Double) -> CIImage? {
        let filter = CIFilter(name: "CIConstantColorGenerator")
        filter?.setValue(CIColor(color: UIColor(white: 1.0, alpha: CGFloat(opacity))), forKey: kCIInputColorKey)
        if let colorImage = filter?.outputImage {
            let compositingFilter = CIFilter(name: "CIMultiplyCompositing")
            compositingFilter?.setValue(image, forKey: kCIInputImageKey)
            compositingFilter?.setValue(colorImage, forKey: kCIInputBackgroundImageKey)
            return compositingFilter?.outputImage
        }
        return nil
    }
    
    func cropImage(_ image: CIImage, toRect rect: CGRect) -> CIImage {
        return image.cropped(to: rect)
    }
    
    func blendImages(mainImage: CIImage, grainImage: CIImage, blendMode: String) -> CIImage? {
        guard let blendFilter = CIFilter(name: blendMode) else {
            print("Invalid blend mode: \(blendMode)")
            return nil
        }
        blendFilter.setValue(grainImage, forKey: kCIInputImageKey)
        blendFilter.setValue(mainImage, forKey: kCIInputBackgroundImageKey)
        return blendFilter.outputImage
    }
    
    func scaleImage(_ image: CIImage, toSize targetSize: CGSize) -> CIImage? {
        let sourceExtent = image.extent
        let scaleX = targetSize.width / sourceExtent.width
        let scaleY = targetSize.height / sourceExtent.height
        let scale = max(scaleX, scaleY) // Use max to ensure the grain image covers the main image entirely

        guard let lanczosFilter = CIFilter(name: "CILanczosScaleTransform") else {
            print("CILanczosScaleTransform filter not found")
            return nil
        }
        lanczosFilter.setValue(image, forKey: kCIInputImageKey)
        lanczosFilter.setValue(scale, forKey: kCIInputScaleKey)
        lanczosFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        // Apply scaling
        if let scaledImage = lanczosFilter.outputImage {
            // Calculate the cropping rect to center the grain image over the main image
            let x = (scaledImage.extent.width - targetSize.width) / 2.0
            let y = (scaledImage.extent.height - targetSize.height) / 2.0
            let cropRect = CGRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
            // Crop the scaled image to the target size
            return scaledImage.cropped(to: cropRect)
        }
        return nil
    }

    func overlayImageWithBlendMode(mainImage: CIImage, overlayImage: CIImage, opacity: Double, blendMode: String) -> CIImage? {
        let mainImageSize = mainImage.extent.size
        // Scale the grain image
        if let scaledGrainImage = scaleImage(overlayImage, toSize: mainImageSize),
           let adjustedGrainImage = adjustOpacity(of: scaledGrainImage, opacity: opacity),
           let blendedCIImage = blendImages(mainImage: mainImage, grainImage: adjustedGrainImage, blendMode: blendMode) {
            
            // Crop the blended image to the main image's extent (optional, if not already matching)
            let croppedImage = cropImage(blendedCIImage, toRect: mainImage.extent)
            
            return croppedImage
        } else {
            return nil
        }
    }

}
