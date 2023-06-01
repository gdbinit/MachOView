//
//  MVRow.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation
import AppKit

enum MVColorOrdinal: Int {
    case black = 1
    case darkGray
    case lightGray
    case white
    case gray
    case red
    case green
    case blue
    case cyan
    case yellow
    case magenta
    case orange
    case purple
    case brown
    
    init?(color: NSColor) {
        if color == .black {
            self = MVColorOrdinal.black
        } else if color == .darkGray {
            self = MVColorOrdinal.darkGray
        } else if color == .lightGray {
            self = MVColorOrdinal.lightGray
        } else if color == .white {
            self = MVColorOrdinal.white
        } else if color == .gray {
            self = MVColorOrdinal.gray
        } else if color == .red {
            self = MVColorOrdinal.red
        } else if color == .green {
            self = MVColorOrdinal.green
        } else if color == .blue {
            self = MVColorOrdinal.blue
        } else if color == .cyan {
            self = MVColorOrdinal.cyan
        } else if color == .yellow {
            self = MVColorOrdinal.yellow
        } else if color == .magenta {
            self = MVColorOrdinal.magenta
        } else if color == .orange {
            self = MVColorOrdinal.orange
        } else if color == .purple {
            self = MVColorOrdinal.purple
        } else if color == .brown {
            self = MVColorOrdinal.brown
        }
    }
    
    static func colorOrdinal(color: NSColor) -> Int {
        if color == .black {
            return MVColorOrdinal.black.rawValue
        } else if color == .darkGray {
            return MVColorOrdinal.darkGray.rawValue
        } else if color == .lightGray {
            return MVColorOrdinal.lightGray.rawValue
        } else if color == .white {
            return MVColorOrdinal.white.rawValue
        } else if color == .gray {
            return MVColorOrdinal.gray.rawValue
        } else if color == .red {
            return MVColorOrdinal.red.rawValue
        } else if color == .green {
            return MVColorOrdinal.green.rawValue
        } else if color == .blue {
            return MVColorOrdinal.blue.rawValue
        } else if color == .cyan {
            return MVColorOrdinal.cyan.rawValue
        } else if color == .yellow {
            return MVColorOrdinal.yellow.rawValue
        } else if color == .magenta {
            return MVColorOrdinal.magenta.rawValue
        } else if color == .orange {
            return MVColorOrdinal.orange.rawValue
        } else if color == .purple {
            return MVColorOrdinal.purple.rawValue
        } else if color == .brown {
            return MVColorOrdinal.brown.rawValue
        }
        return 0
    }
    
}

public final class MVRow: NSObject {
    let column: MVColumn
    let attributes: [String: String]
    let offset: UInt64
    var columnsOffset: UInt64
    let attributesOffset: UInt64
    let deleted: Bool
    let dirty: Bool
    
    init(column: MVColumn,
         attributes: [String : String],
         offset: UInt64,
         columnsOffset: UInt64,
         attributesOffset: UInt64,
         deleted: Bool,
         dirty: Bool) {
        self.column = column
        self.attributes = attributes
        self.offset = offset
        self.columnsOffset = columnsOffset
        self.attributesOffset = attributesOffset
        self.deleted = deleted
        self.dirty = dirty
    }
    
    func column(at index: ColumnProperty) -> String {
        switch index {
        case .offset:
            return column.offsetStr
        case .data:
            return column.dataStr
        case .description:
            return column.descriptionStr
        case .value:
            return column.valueStr
        }
    }
    
    func replaceColumn(at index: ColumnProperty, with string: String) {
        columnsOffset = 0
        switch index {
        case .offset:
            column.offsetStr = string
        case .data:
            column.dataStr = string
        case .description:
            column.descriptionStr = string
        case .value:
            column.valueStr = string
        }
    }
    
}

extension MVRow: MVSerializing {
    func loadFromFile(_ fileHandle: FileHandle) {
        
    }
    
    func saveToFile(_ fileHandle: FileHandle) {
        
    }
    
    func clear() {
        
    }
}
extension MVRow {
    
    func write(_ string: String?, to fileHandle: FileHandle) {
        if let data = string?.data(using: .utf8) {
            fileHandle.write(data)
        } else {
            let char: Character = "\0"
            let data = String(char).data(using: .utf8)!
            fileHandle.write(data)
        }
    }
    
    func readString(from fileHandle: FileHandle) -> String? {
        var data = Data()
        var char: UInt8 = 0
        repeat {
            char = fileHandle.readData(ofLength: 1).first ?? 0
            data.append(char)
        } while char != 0
        return String(data: data, encoding: .utf8)
    }
    
    func write(_ color: NSColor, to fileHandle: FileHandle) {
        let colorOrdinal = MVColorOrdinal(color: color)?.rawValue ?? 0
        fileHandle.write(Data([colorOrdinal]))
        if colorOrdinal == 0 {
            var fred: Float = 0, fgreen: Float = 0, fblue: Float = 0, falpha: Float = 0
            color.getRed(&fred, green: &fgreen, blue: &fblue, alpha: &falpha)
            fileHandle.write(Data(bytes: &fred, count: MemoryLayout<Float>.size))
            fileHandle.write(Data(bytes: &fgreen, count: MemoryLayout<Float>.size))
            fileHandle.write(Data(bytes: &fblue, count: MemoryLayout<Float>.size))
            fileHandle.write(Data(bytes: &falpha, count: MemoryLayout<Float>.size))
        }
    }
    
}

//-----------------------------------------------------------------------------
- (void)writeColor:(NSColor *)color toFile:(FILE *)pFile
{
  int colorOrdinal = [color isEqualTo:[NSColor blackColor]]     ? MVBlackColorOrdinal
                   : [color isEqualTo:[NSColor darkGrayColor]]  ? MVDarkGrayColorOrdinal
                   : [color isEqualTo:[NSColor lightGrayColor]] ? MVLightGrayColorOrdinal
                   : [color isEqualTo:[NSColor whiteColor]]     ? MVWhiteColorOrdinal
                   : [color isEqualTo:[NSColor grayColor]]      ? MVGrayColorOrdinal
                   : [color isEqualTo:[NSColor redColor]]       ? MVRedColorOrdinal
                   : [color isEqualTo:[NSColor greenColor]]     ? MVGreenColorOrdinal
                   : [color isEqualTo:[NSColor blueColor]]      ? MVBlueColorOrdinal
                   : [color isEqualTo:[NSColor cyanColor]]      ? MVCyanColorOrdinal
                   : [color isEqualTo:[NSColor yellowColor]]    ? MVYellowColorOrdinal
                   : [color isEqualTo:[NSColor magentaColor]]   ? MVMagentaColorOrdinal
                   : [color isEqualTo:[NSColor orangeColor]]    ? MVOrangeColorOrdinal
                   : [color isEqualTo:[NSColor purpleColor]]    ? MVPurpleColorOrdinal
                   : [color isEqualTo:[NSColor brownColor]]     ? MVBrownColorOrdinal
                   : 0;
  
  putc(colorOrdinal, pFile);
  if (colorOrdinal == 0) {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    float fred = red, fgreen = green, fblue = blue, falpha = alpha;
    fwrite(&fred, sizeof(float), 1, pFile);
    fwrite(&fgreen, sizeof(float), 1, pFile);
    fwrite(&fblue, sizeof(float), 1, pFile);
    fwrite(&falpha, sizeof(float), 1, pFile);
  }
}

//-----------------------------------------------------------------------------
- (NSColor *)readColorFromFile:(FILE *)pFile
{
  int colorOrdinal = getc(pFile);
  switch (colorOrdinal)
  {
    case MVBlackColorOrdinal:     return [NSColor blackColor];
    case MVDarkGrayColorOrdinal:  return [NSColor darkGrayColor];
    case MVLightGrayColorOrdinal: return [NSColor lightGrayColor];
    case MVWhiteColorOrdinal:     return [NSColor whiteColor];
    case MVGrayColorOrdinal:      return [NSColor grayColor];
    case MVRedColorOrdinal:       return [NSColor redColor];
    case MVGreenColorOrdinal:     return [NSColor greenColor];
    case MVBlueColorOrdinal:      return [NSColor blueColor];
    case MVCyanColorOrdinal:      return [NSColor cyanColor];
    case MVYellowColorOrdinal:    return [NSColor yellowColor];
    case MVMagentaColorOrdinal:   return [NSColor magentaColor];
    case MVOrangeColorOrdinal:    return [NSColor orangeColor];
    case MVPurpleColorOrdinal:    return [NSColor purpleColor];
    case MVBrownColorOrdinal:     return [NSColor brownColor];
  }

  float fred, fgreen, fblue, falpha;
  fread(&fred, sizeof(float), 1, pFile);
  fread(&fgreen, sizeof(float), 1, pFile);
  fread(&fblue, sizeof(float), 1, pFile);
  fread(&falpha, sizeof(float), 1, pFile);
  return [NSColor colorWithDeviceRed:fred green:fgreen blue:fblue alpha:falpha];
}

//----------------------------------------------------------------------------
- (void)saveAttributestoFile:(FILE *)pFile
{
    uint64_t numAttributes = [attributes count];
    if (fwrite (&numAttributes, sizeof(uint64_t), 1, pFile) < 1) {
        NSLog(@"fwrite failed in saveAttributestoFile:");
        return;
    }
  
  for (NSString * key in [attributes allKeys]) {
    id value = [attributes objectForKey:key];
    if (value == nil) {
      continue;
    }
    
    int keyOrdinal = [key isEqualToString:MVUnderlineAttributeName] ? MVUnderlineAttributeOrdinal
                   : [key isEqualToString:MVCellColorAttributeName] ? MVCellColorAttributeOrdinal
                   : [key isEqualToString:MVTextColorAttributeName] ? MVTextColorAttributeOrdinal
                   : [key isEqualToString:MVMetaDataAttributeName] ? MVMetaDataAttributeOrdinal
                   : 0;

    putc(keyOrdinal, pFile);
    switch (keyOrdinal)
    {
      case MVUnderlineAttributeOrdinal: [self writeString:value toFile:pFile]; break;
      case MVCellColorAttributeOrdinal: [self writeColor:value toFile:pFile]; break;
      case MVTextColorAttributeOrdinal: [self writeColor:value toFile:pFile]; break;
      case MVMetaDataAttributeOrdinal:  [self writeString:value toFile:pFile]; break;
      default: NSLog(@"warning: unknown attribute key");
    }
  }
}

//----------------------------------------------------------------------------
- (void)loadAttributesFromFile:(FILE *)pFile
{
  uint64_t numAttributes;
  fread(&numAttributes, sizeof(uint64_t), 1, pFile);
  
  NSMutableDictionary * _attributes = [[NSMutableDictionary alloc] initWithCapacity:numAttributes];
  while (numAttributes-- > 0)
  {
    int keyOrdinal = getc(pFile);
    switch (keyOrdinal)
    {
      case MVUnderlineAttributeOrdinal: [_attributes setObject:[self readStringFromFile:pFile] forKey:MVUnderlineAttributeName]; break;
      case MVCellColorAttributeOrdinal: [_attributes setObject:[self readColorFromFile:pFile] forKey:MVCellColorAttributeName]; break;
      case MVTextColorAttributeOrdinal: [_attributes setObject:[self readColorFromFile:pFile] forKey:MVTextColorAttributeName]; break;
      case MVMetaDataAttributeOrdinal:  [_attributes setObject:[self readStringFromFile:pFile] forKey:MVMetaDataAttributeName]; break;
      default: NSLog(@"warning: unknown attribute key");
    }
  }
  
  attributes = _attributes;
}

//----------------------------------------------------------------------------
- (void)saveToFile:(FILE *)pFile
{
    // dont need to seek, we always append new items
    if (columnsOffset == 0) { // isSaved == NO
        off_t filePos = ftello(pFile);
        if (filePos == -1) {
            NSLog(@"MVRow saveToFile: ftello failed: %s", strerror(errno));
        }
        [self writeString:columns.offsetStr toFile:(FILE *)pFile];
        [self writeString:columns.dataStr toFile:(FILE *)pFile];
        [self writeString:columns.descriptionStr toFile:(FILE *)pFile];
        [self writeString:columns.valueStr toFile:(FILE *)pFile];
        columnsOffset = filePos;
    }
  
    if (dirty) {
        // reload the attributes if they are out of cache
        if (attributesOffset > 0) {
            // import new items
            NSMutableDictionary * _attributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
            // load old attributes
            if (fseeko(pFile, attributesOffset, SEEK_SET) == -1) {
                NSLog(@"MVRow saveToFile: fseeko SEEK_SET failed: %s", strerror(errno));
            }
            [self loadAttributesFromFile:pFile];
            if (fseeko(pFile, 0, SEEK_END) == -1) {
                NSLog(@"MVRow saveToFile: fseeko SEEK_END failed: %s", strerror(errno));
            }
            // extend stored attributes with loaded items
            [_attributes addEntriesFromDictionary:attributes];
            // store extended attributes
            attributes = _attributes;
        }
    
        off_t filePos = ftello(pFile);
        if (filePos == -1) {
            NSLog(@"MVRow saveToFile: ftello failed: %s", strerror(errno));
        }
        [self saveAttributestoFile:(FILE *)pFile];
        dirty = NO;
        attributesOffset = filePos;
    }
}

//----------------------------------------------------------------------------
- (void)loadFromFile:(FILE *)pFile
{
    if (columns == nil) {
        NSParameterAssert(columnsOffset != 0);
    
        if (fseeko(pFile, columnsOffset, SEEK_SET) == 0) {
            columns = [[MVColumns alloc] init];
            columns.offsetStr = [self readStringFromFile:pFile];
            columns.dataStr = [self readStringFromFile:pFile];
            columns.descriptionStr = [self readStringFromFile:pFile];
            columns.valueStr = [self readStringFromFile:pFile];
        } else {
            NSLog(@"*** reading error (columns) '%s'",strerror(errno));
            NSParameterAssert(0);
            return;
        }
    }
  
    if (attributes == nil && attributesOffset > 0) {
        if (fseeko(pFile, attributesOffset, SEEK_SET) == 0) {
            [self loadAttributesFromFile:pFile];
        } else {
            NSLog(@"*** reading error (attributes) '%s'",strerror(errno));
            NSParameterAssert(0);
        }
    }
}

//----------------------------------------------------------------------------
- (void)saveIndexToFile:(FILE *)pFile
{
  fwrite(&offset, sizeof(uint32_t), 1, pFile);
  fwrite(&columnsOffset, sizeof(uint32_t), 1, pFile);
  fwrite(&attributesOffset, sizeof(uint32_t), 1, pFile);
  fwrite(&deleted, sizeof(BOOL), 1, pFile);
}

//----------------------------------------------------------------------------
- (void)loadIndexFromFile:(FILE *)pFile
{
  fread(&offset, sizeof(uint32_t), 1, pFile);
  fread(&columnsOffset, sizeof(uint32_t), 1, pFile);
  fread(&attributesOffset, sizeof(uint32_t), 1, pFile);
  fread(&deleted, sizeof(BOOL), 1, pFile);
}

//----------------------------------------------------------------------------
-(BOOL) isSaved
{
  return (columnsOffset > 0);
}

//----------------------------------------------------------------------------
-(void) clear
{
  if (columnsOffset > 0) // isSaved == YES
  {
    columns = nil;

    if (dirty == NO)
    {
      attributes = nil;
    }
  }
}

@end
