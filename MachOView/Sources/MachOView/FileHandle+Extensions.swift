//
//  FileHandle+Int.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation
import AppKit

extension FileHandle {
    
    func writeByte(_ byte: UInt8) {
        write(Data([byte]))
    }

    func readByte() -> UInt8? {
      do {
        if let data = try read(upToCount: 1) {
          return data.byte
        }
      } catch {
        fatalError("read UInt8 error: \(error)")
      }
      return nil
    }
    
    func writeFloat(_ float: Float) {
        var writeFloat = float
        let data = Data(bytes: &writeFloat, count: MemoryLayout<Float>.size)
        write(data)
    }
    
    func readFloat() -> Float? {
      do {
          if let data = try read(upToCount: MemoryLayout<Float>.size) {
              return data.float
          }
      } catch {
        fatalError("read Float error: \(error)")
      }
      return nil
    }
    
    func writeColor(_ color: NSColor) {
        var fred: CGFloat = 0, fgreen: CGFloat = 0, fblue: CGFloat = 0, falpha: CGFloat = 0
        color.getRed(&fred, green: &fgreen, blue: &fblue, alpha: &falpha)
        writeFloat(Float(fred))
        writeFloat(Float(fgreen))
        writeFloat(Float(fblue))
        writeFloat(Float(falpha))
    }
    
    func readColor() -> NSColor? {
        guard let fred = readFloat(),
              let fgreen = readFloat(),
              let fblue = readFloat(),
              let falpha = readFloat() else {
            return nil
        }
        return NSColor(red: CGFloat(fred), green: CGFloat(fgreen), blue: CGFloat(fblue), alpha: CGFloat(falpha))
    }
}

extension Data {
    var byte: UInt8 {
        withUnsafeBytes { unsafeRawBufferPointer in
            unsafeRawBufferPointer.load(as: UInt8.self)
        }
    }
    
    var float: Float {
      withUnsafeBytes { unsafeRawBufferPointer in
        unsafeRawBufferPointer.load(as: Float.self)
      }
    }
}
