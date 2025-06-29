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


extension Publisher {
    func shareReplay(maxValues: Int = 0) -> AnyPublisher<Output, Failure> {
        multicast(subject: ReplaySubject(maxValues: maxValues)).autoconnect().eraseToAnyPublisher()
    }
}

final class ReplaySubject<Input, Failure: Error>: Subject {
    typealias Output = Input
    private var recording = Record<Input, Failure>.Recording()
    private let stream = PassthroughSubject<Input, Failure>()
    private let maxValues: Int
    private let lock = NSRecursiveLock()
    private var completed = false
  
    init(maxValues: Int = 0) {
        self.maxValues = maxValues
    }
    func send(subscription: Subscription) {
        subscription.request(maxValues == 0 ? .unlimited : .max(maxValues))
    }
    func send(_ value: Input) {
      lock.lock(); defer { lock.unlock() }
        recording.receive(value)
        stream.send(value)
        if recording.output.count == maxValues {
            send(completion: .finished)
        }
    }
    func send(completion: Subscribers.Completion<Failure>) {
      lock.lock(); defer { lock.unlock() }
      if !completed {
        completed = true
        recording.receive(completion: completion)
      }
      stream.send(completion: completion)
    }
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Input == S.Input {
      lock.lock(); defer { lock.unlock() }
        Record(recording: self.recording)
            .append(self.stream)
            .receive(subscriber: subscriber)
    }
}
