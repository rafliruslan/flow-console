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


import Combine
import Foundation


public class BlinkLogging {
  public typealias LogHandlerParameters = (Publishers.Share<AnyPublisher<[BlinkLogKeys:Any], Never>>)
  public typealias LogHandlerFactory = ((LogHandlerParameters) throws -> AnyCancellable)
  fileprivate static var handlers = [LogHandlerFactory]()
  
  public static func handle(_ handler: @escaping LogHandlerFactory) {
    self.handlers.append(handler)
  }
  
  public static func reset() {
    self.handlers = []
  }
}

enum BlinkLoggingHandlers {
  static func print(logPublisher: BlinkLogging.LogHandlerParameters) -> AnyCancellable {
    logPublisher.filter(logLevel: .debug)
      .format { [
        "[\(Date().formatted(.iso8601))]",
        "[\($0[.logLevel] ?? BlinkLogLevel.log)]",
        $0[.component] as? String ?? "global",
        $0[.message] as? String ?? ""
      ].joined(separator: " : ") }
      .sinkToOutput()
  }
}

// BlinkLogging.handler { $0.map {}.sinkTo }
public struct BlinkLogKeys: Hashable {
  private let rawValue: String
  
  static let message    = BlinkLogKeys("message")
  static let logLevel   = BlinkLogKeys("logLevel")
  static let component  = BlinkLogKeys("component")
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum BlinkLogLevel: Int, Comparable, CustomStringConvertible {
  case trace
  case debug
  case info
  case warn
  case error
  case fatal
  // Skips or overrides.
  case log
  
  public static func < (lhs: BlinkLogLevel, rhs: BlinkLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
  
  public var description: String {
    switch self {
    case .trace: "TRACE"
    case .debug: "DEBUG"
    case .info: "INFO"
    case .warn: "WARN"
    case .error: "ERROR"
    case .fatal: "FATAL"
    case .log: "LOG"
    }
  }
}

class BlinkLogger: Subject {
  typealias Output = [BlinkLogKeys:Any]
  typealias Failure = Never
  
  private let sub = PassthroughSubject<Output, Never>()
  private var logger = Set<AnyCancellable>()

  public func send(_ value: Output) {
    sub.send(value)
  }
  
  func send(completion: Subscribers.Completion<Failure>) {
    sub.send(completion: completion)
  }
  
  func send(subscription: Subscription) {
    sub.send(subscription: subscription)
  }
  
  func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, [BlinkLogKeys : Any] == S.Input {
    sub.receive(subscriber: subscriber)
  }
  
  public init(bootstrap: ((AnyPublisher<Output, Never>) -> (AnyPublisher<Output, Never>))? = nil,
              handlers: [BlinkLogging.LogHandlerFactory]? = nil) {
    var publisher = sub.eraseToAnyPublisher()
    if let bootstrap = bootstrap {
      publisher = bootstrap(publisher)
    }

    let handlers = handlers ?? BlinkLogging.handlers
    handlers.forEach { handle in
      do {
        try handle(publisher.share()).store(in: &logger)
      } catch {
        Swift.print("Error initializing logging handler - \(error)")
      }
    }
  }
}

extension BlinkLogger {
  public func send(_ message: String)   { self.send([.logLevel: BlinkLogLevel.log,
                                                   .message: message,]) }

  public func trace(_ message: String)  { self.send([.logLevel: BlinkLogLevel.trace,
                                                   .message: message,]) }
  public func debug(_ message: String)  { self.send([.logLevel: BlinkLogLevel.debug,
                                                   .message: message,]) }
  public func info(_ message: String)   { self.send([.logLevel: BlinkLogLevel.info,
                                                   .message: message,]) }
  public func warn(_ message: String)   { self.send([.logLevel: BlinkLogLevel.warn,
                                                   .message: message,]) }
  public func error(_ message: String)  { self.send([.logLevel: BlinkLogLevel.error,
                                                   .message: message,]) }
  public func fatal(_ message: String)  { self.send([.logLevel: BlinkLogLevel.fatal,
                                                   .message: message,]) }
}

extension BlinkLogger {
  convenience init(_ component: String,  
                   handlers: [BlinkLogging.LogHandlerFactory]? = nil) {
    self.init(bootstrap: {
      $0.map { $0.merging([BlinkLogKeys.component: component], uniquingKeysWith: { (_, new) in new }) }
        .eraseToAnyPublisher()
    }, handlers: handlers)
  }
}
