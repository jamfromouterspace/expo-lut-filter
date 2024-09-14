import ExpoModulesCore
import Foundation
import UIKit

public class ExpoLutFilterModule: Module {
    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    public func definition() -> ModuleDefinition {
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('ExpoLutFilter')` in JavaScript.
        Name("ExpoLutFilter")
        
        
        // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
        Function("hello") {
            return "Hello world! 👋"
        }
        
        // Defines a JavaScript function that always returns a Promise and whose native code
        // is by default dispatched on the different thread than the JavaScript runtime runs on.
        AsyncFunction("applyLUT") { (inputImageUri: String, lutUri: String, lutDimension: Int) in
            let lut = loadCGImage(from: lutUri)
            enum InputError: Error {
                case failedToLoadLUT
                case failedToLoadInputImage
            }
            if lut == nil {
                throw InputError.failedToLoadLUT
            }
            let lutImageSource = ImageSource(cgImage: lut!)
            let input = loadCIImage(from: inputImageUri)
            if input == nil {
                throw InputError.failedToLoadInputImage
            }
            let filter = FilterColorCube(identifier: UUID().uuidString, lutImage: lutImageSource, dimension: lutDimension)
            let outputCI = filter.apply(to: input!)
            let outputUri = saveCIImageToCache(outputCI)
            return outputUri?.absoluteString
        }
    }
    
    func renderCIImageToCGImage(_ ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil) // Create a Core Image context
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    func saveCIImageToCache(_ ciImage: CIImage) -> URL? {
        // Render the CIImage to a CGImage
        guard let cgImage = renderCIImageToCGImage(ciImage) else {
            print("Failed to render CGImage from CIImage")
            return nil
        }
        
        
        // Convert CGImage to UIImage (optional but simplifies saving)
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert UIImage to Data (choose PNG or JPEG format)
        guard let imageData = uiImage.pngData() else {
            print("Failed to convert UIImage to PNG data")
            return nil
        }
        
        // Step 3: Save Data to the cache directory
        let fileManager = FileManager.default
        
        // Get the cache directory URL
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to get cache directory")
            return nil
        }
        
        // Create a unique file name
        let fileName = UUID().uuidString + ".png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Write the image data to the cache directory
        do {
            try imageData.write(to: fileURL)
            print("Image saved to cache directory: \(fileURL)")
            return fileURL
        } catch {
            print("Error saving image to cache: \(error)")
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
}
