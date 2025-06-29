//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Based on Blink Shell for iOS
// Original Copyright (C) 2016-2024 Blink Shell contributors
// Flow Console modifications Copyright (C) 2024 Flow Console Project
//
// This file is part of Flow Console.
//
// Flow Console is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Flow Console is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Flow Console. If not, see <http://www.gnu.org/licenses/>.
//
// Original Blink Shell project: https://github.com/blinksh/blink
// Flow Console project: https://github.com/rafliruslan/flow-console
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import Combine
import Dispatch

public struct CopyError : Error {
  public let msg: String
}


public struct CopyAttributesFlag: OptionSet {
  public var rawValue: UInt
  
  public static let none = CopyAttributesFlag([])
  public static let timestamp = CopyAttributesFlag(rawValue: 1 << 0)
  public static let permissions = CopyAttributesFlag(rawValue: 1 << 1)
  
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
  
  func filter(_ attrs: FileAttributes) -> FileAttributes {
    var newAttrs: FileAttributes = [:]
    
    if self.contains(.timestamp) {
      newAttrs[.creationDate] = attrs[.creationDate]
      newAttrs[.modificationDate] = attrs[.modificationDate]
    }
    if self.contains(.permissions) {
      newAttrs[.posixPermissions] = attrs[.posixPermissions]
    }
    
    return newAttrs
  }
}

public struct CopyArguments {
  public let inplace: Bool
  public var preserve: CopyAttributesFlag // attributes. Check how FileManager passes this.
  public let checkTimes: Bool
  
  public init(inplace: Bool = true,
              preserve: CopyAttributesFlag = [.permissions],
              checkTimes: Bool = false) {
    self.inplace = inplace
    self.preserve = preserve
    self.checkTimes = checkTimes
    
    if checkTimes {
      self.preserve.insert(.timestamp)
    }
  }
}

extension Translator {
  public func copy(from ts: [Translator], args: CopyArguments = CopyArguments()) -> CopyProgressInfoPublisher {
    print("Copying \(ts.count) elements")
    return ts.publisher.compactMap { t in
      t.fileType == .typeDirectory || t.fileType == .typeRegular ? t : nil
    }.flatMap(maxPublishers: .max(1)) { t in
      copyElement(from: t, args: args)
    }.eraseToAnyPublisher()
  }

  public func copy(from t: Translator, newName: String, args: CopyArguments = CopyArguments()) -> CopyProgressInfoPublisher {
    print("Copying as \(newName)")
    return self.cloneWalkTo(newName)
      .tryCatch { _ -> AnyPublisher<Translator, Error> in
        return self.create(name: newName, mode: S_IRWXU)
          .flatMap { $0.close() }
          .flatMap { _ in self.cloneWalkTo(newName) }
          .eraseToAnyPublisher()
      }
      .flatMap { $0.copyElement(from: t, args: args) }
      .eraseToAnyPublisher()
  }

  // Self can be a File or a directory.
  fileprivate func copyElement(from t: Translator, args: CopyArguments) -> CopyProgressInfoPublisher {
    return Just(t)
      .flatMap() { $0.stat() }
      .tryMap { attrs -> (String, NSNumber, FileAttributes) in
        guard let name = attrs[FileAttributeKey.name] as? String else {
          throw CopyError(msg: "No name provided")
        }
        
        let passingAttributes = args.preserve.filter(attrs)
        // TODO Two ways to set permissions. Should be part of the CopyArguments
        // The equivalent of -P is simpler for now.
        // https://serverfault.com/questions/639042/does-openssh-sftp-server-use-umask-or-preserve-client-side-permissions-after-put
        // let mode = attrs[FileAttributeKey.posixPermissions] as? NSNumber ??
        // (t.fileType == .typeDirectory ? NSNumber(value: Int16(0o755)) : NSNumber(value: Int16(0o644)))
        
        guard let size = attrs[FileAttributeKey.size] as? NSNumber else {
          throw CopyError(msg: "No size provided")
        }
        
        return (name, size, passingAttributes)
      }.flatMap { (name, size, passingAttributes) -> CopyProgressInfoPublisher in
        print("Processing \(name)")
        switch t.fileType {
        case .typeDirectory:
          let mode = passingAttributes[FileAttributeKey.posixPermissions] as? NSNumber ?? NSNumber(value: Int16(0o755))
          return self.copyDirectory(as: name, from: t, mode: mode, args: args)
        default:
          let copyFilePublisher = self.copyFile(from: t, name: name, size: size, attributes: passingAttributes)
          
          // When checkTimes, copy the file only if the modificationDate is different
          if args.checkTimes {
            let fileTranslator = self.isDirectory ? self.cloneWalkTo(name) : .just(self)
            return fileTranslator
              .flatMap { $0.stat() }
              .catch { _ in Just([:]) }
              .flatMap { localAttributes -> CopyProgressInfoPublisher in
                if let localModificationDate = localAttributes[.modificationDate] as? NSDate,
                   localModificationDate == (passingAttributes[.modificationDate] as? NSDate) {
                  let fullFile = (self.current as NSString).appendingPathComponent(name)
                  return .just(CopyProgressInfo(name: fullFile, written: 0, size: size.uint64Value))
                }
                return copyFilePublisher
              }.eraseToAnyPublisher()
          }
          
          return copyFilePublisher
        }
      }.eraseToAnyPublisher()
  }
  
  fileprivate func copyDirectory(as name: String,
                                 from t: Translator,
                                 mode: NSNumber,
                                 args: CopyArguments) -> CopyProgressInfoPublisher {
    print("Copying directory \(t.current)")
    
    let directory: AnyPublisher<Translator, Error>
    if args.checkTimes {
      // Walk or create
      directory = self.cloneWalkTo(name)
        .tryCatch { _ in self.clone().mkdir(name: name, mode: mode_t(truncating: mode)) }
        .eraseToAnyPublisher()
    } else {
      directory = self.clone().mkdir(name: name, mode: mode_t(truncating: mode))
    }
    
    return directory
      .flatMap { dir -> CopyProgressInfoPublisher in
        t.directoryFilesAndAttributes().flatMap {
          $0.compactMap { i -> FileAttributes? in
            if (i[.name] as! String) == "." || (i[.name] as! String) == ".." {
              return nil
            } else {
              return i
            }
          }.publisher
        }.flatMap { t.cloneWalkTo($0[.name] as! String) }
        .collect()
        .flatMap { dir.copy(from: $0, args: args) }.eraseToAnyPublisher()
      }.eraseToAnyPublisher()
    
//    return t.directoryFilesAndAttributes().flatMap {
//      $0.compactMap { i -> FileAttributes? in
//        if (i[.name] as! String) == "." || (i[.name] as! String) == ".." {
//          return nil
//        } else {
//          return i
//        }
//      }.publisher
//    }.flatMap { t.cloneWalkTo($0[.name] as! String) }
//    .collect()
//    .flatMap { self.copy(from: $0) }.eraseToAnyPublisher()
  }
}

fileprivate enum FileState {
  case copy(File)
  case attributes(File)
}

extension Translator {
  fileprivate func copyFile(from t: Translator,
                            name: String,
                            size: NSNumber,
                            attributes: FileAttributes) -> CopyProgressInfoPublisher {

    let fullFile: String
    let file: AnyPublisher<File, Error>
    // If we are a directory, we create the file. If we are a file, we open truncated.
    if self.isDirectory {
      fullFile = (self.current as NSString).appendingPathComponent(name)
      file = self.create(name: name, mode: S_IRWXU)
    } else {
      fullFile = self.current
      file = self.open(flags: O_WRONLY | O_TRUNC)
    }
    
    return file
      .flatMap { destination -> CopyProgressInfoPublisher in
        if size == 0 {
          return .just(CopyProgressInfo(name: fullFile, written:0, size: 0))
        }
        
        return t.open(flags: O_RDONLY)
          .flatMap { [FileState.copy($0), FileState.attributes($0)].publisher }
          .flatMap(maxPublishers: .max(1)) { state -> CopyProgressInfoPublisher in
            switch state {
            case .copy(let source):
              return (source as! WriterTo)
                .writeTo(destination)
                .map { CopyProgressInfo(name: fullFile, written: UInt64($0), size: size.uint64Value) }
                .eraseToAnyPublisher()
            case .attributes(let source):
              return Publishers.Zip(source.close(), destination.close())
                // TODO From the File, we could offer the Translator itself.
                .flatMap { _ in self.isDirectory ?
                  self.cloneWalkTo(name).flatMap { $0.wstat(attributes) }.eraseToAnyPublisher() :
                  self.wstat(attributes)
                }
                .map { _ in CopyProgressInfo(name: fullFile, written: 0, size: size.uint64Value) }
                .eraseToAnyPublisher()
            }
          }.eraseToAnyPublisher()
      }.eraseToAnyPublisher()
  }
}
