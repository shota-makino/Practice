import UIKit
import Foundation
import Accelerate

public struct Pixel {
    public var value: UInt32
    
    public var red: UInt8 {
        get {
            return UInt8(value & 0xFF)
        }
        set {
            value = UInt32(newValue) | (value & 0xFFFFFF00)
        }
    }
    
    public var green: UInt8 {
        get {
            return UInt8((value >> 8) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF)
        }
    }
    
    public var blue: UInt8 {
        get {
            return UInt8((value >> 16) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF)
        }
    }
    
    public var alpha: UInt8 {
        get {
            return UInt8((value >> 24) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF)
        }
    }
}

public struct RGBAImage {
    public var pixels: [Pixel]
    
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        guard let cgImage = image.CGImage else { return nil }
        
        // Redraw image for correct pixel format
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bytesPerRow = width * 4
        
        let imageData = UnsafeMutablePointer<Pixel>.alloc(width * height)
        
        guard let imageContext = CGBitmapContextCreate(imageData, width, height, 8, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
        CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: image.size), cgImage)
        
        let bufferPointer = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
        pixels = Array(bufferPointer)
        
        imageData.destroy()
        imageData.dealloc(width * height)
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        
        let bytesPerRow = width * 4
        
        let imageDataReference = UnsafeMutablePointer<Pixel>(pixels)
        defer {
            imageDataReference.destroy()
        }
        let imageContext = CGBitmapContextCreateWithData(imageDataReference, width, height, 8, bytesPerRow, colorSpace, bitmapInfo, nil, nil)
        
        guard let cgImage = CGBitmapContextCreateImage(imageContext) else {return nil}
        let image = UIImage(CGImage: cgImage)
        
        return image
    }
}


public struct RGBAChannels {
    public var red: [UInt8] = []
    public var green: [UInt8] = []
    public var blue: [UInt8] = []
    public var alpha: [UInt8] = []
    
    public init(image:RGBAImage) {
        for i in 0..<image.height {
            for j in 0..<image.width {
                let index = i * image.width + j
                let pixel = image.pixels[index]
                red.append(pixel.red)
                green.append(pixel.green)
                blue.append(pixel.blue)
                alpha.append(pixel.alpha)
            }
        }
    }

    public func toRGBAImage(inout image: RGBAImage) {
        for i in 0..<image.height {
            for j in 0..<image.width {
                let index = i * image.width + j
                var pixel = Pixel(value: 0)
                pixel.red = red[index]
                pixel.green = green[index]
                pixel.blue = blue[index]
                pixel.alpha = alpha[index]
                image.pixels[index] = pixel
            }
        }
    }
}


