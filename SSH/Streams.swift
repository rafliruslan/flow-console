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
import FlowConsoleFiles
import LibSSH

/**
 * A stream controls, reads and writes the received channel,
 * multiplexed from the client session. It offers ways to connect outside
 * streams to the channel and exposes callbacks on the state.
 * It is responsible to manage the lifetime of the channel.
 */
public class Stream : Reader, Writer, WriterTo {
  let channel: ssh_channel
  let client: SSHClient
  
  var log: SSHLogger { get { client.log } }
  
  var stdoutCancellable: AnyCancellable?
  var stdinCancellable: AnyCancellable?
  var stderrCancellable: AnyCancellable?
  
  // Handle counts internally on long running streams as a helper when debugging,
  // to know if both sides are receiving the same information, or if there is a problem
  // with the flows (usually the Passthrough not sending information due to demand).
  var stdoutBytes = 0
  var stdinBytes = 0
  var stderrBytes = 0
  
  /**
   * The stream offers callbacks when connected to detect closing and failure events
   */
  public var handleCompletion: (() -> ())?
  public var handleFailure: ((Error) -> ())?
  
  init(_ channel: ssh_channel, on client: SSHClient) {
    self.channel = channel
    self.client = client
  }
  
  /**
   * Connect the stream to an output, input and error and let it handle
   * the read/write loop. When the channel is connected, the stream is then
   * responsible to close the channel once the reading side has sent an EOF.
   * The channel will also be closed if there is an error during the connection.
   * This operations are notified outside through callbacks.
   */
  public func connect(stdout out: Writer, stdin input: WriterTo? = nil, stderr err: Writer? = nil) {
    let outstream = OutStream(self)
    let instream = InStream(self)
    let errstream = OutStream(self, isStderr: true)
    
    stdoutCancellable = outstream.writeTo(out)
      .receive(on: client.rloop).sink(
        receiveCompletion: { completion in
          // When the other side has finished or if there is an error, we cancel the stream.
          // https://www.perlmonks.org/bare/?node_id=167036
          switch completion {
          case .failure(let error):
            self.log.message("Connect Stdout failure \(error)", SSH_LOG_WARN)
            // Indicate the failure and cancel the flows. The upper layer
            // then can clean up accordingly.
            self.handleFailure?(error)
            self.cancel()
          default:
            // The channel is complete when both stdout and stderr have received all data.
            self.log.message("Channel complete", SSH_LOG_INFO)
            self.handleCompletion?()
            self.handleCompletion = nil
            self.cancel()
            break
          }
        }, receiveValue: { written in
          self.stdoutBytes += written
          self.log.message("Connect \(written) bytes from stdout \(self.stdoutBytes)", SSH_LOG_DEBUG)
        })
    
    stdinCancellable = input?.writeTo(instream)
      .print("INSTREAM")
      .receive(on: client.rloop).sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let error):
            self.log.message("Stdin failure \(error)", SSH_LOG_WARN)
            self.handleFailure?(error)
            self.cancel()
          default:
            break
          }
          // Tell the channel there will be no more writing
          // We repeat what sendEOF does, but do not want to have another
          // flow.
          self.log.message("Stdin complete. Sending EOF", SSH_LOG_INFO)
          let rc = ssh_channel_send_eof(self.channel)
          if rc != SSH_OK {
            self.handleFailure?(SSHError(rc, forSession: self.client.session))
            self.cancel()
          }
        }, receiveValue: { written in
          self.stdinBytes += written
          self.log.message("Connect \(written) bytes from stdin \(self.stdoutBytes)", SSH_LOG_DEBUG)
        })
    
    if let err = err {
      stderrCancellable = errstream.writeTo(err)
        .receive(on: client.rloop).sink(
          receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
              self.log.message("Connect Stderr failure \(error)", SSH_LOG_WARN)
              // Indicate the failure and cancel the flows. The upper layer
              // then can clean up accordingly.
              self.handleFailure?(error)
              self.cancel()
            default:
              // The channel is complete when both stdout and stderr have received all data.
              self.log.message("Channel complete", SSH_LOG_INFO)
              self.handleCompletion?()
              self.handleCompletion = nil
              self.cancel()
            }
          }, receiveValue: { written in
            self.stderrBytes += written
            self.log.message("Connect \(written) bytes from stderr \(self.stderrBytes)", SSH_LOG_DEBUG)
          })
    }
  }
  
  public func read(max length: Int) -> AnyPublisher<DispatchData, Error> {
    let outstream = OutStream(self)
    return outstream.read(max: length)
  }
  
  public func read_err(max length: Int) -> AnyPublisher<DispatchData, Error> {
    let errstream = OutStream(self, isStderr: true)
    return errstream.read(max: length)
  }
  
  public func write(_ buf: DispatchData, max length: Int) -> AnyPublisher<Int, Error> {
    let instream = InStream(self)
    return instream.write(buf, max: length)
  }
  
  public func writeTo(_ w: Writer) -> AnyPublisher<Int, Error> {
    let outstream = OutStream(self)
    return outstream.writeTo(w)
  }
  
  public func sendEOF() -> AnyPublisher<Void, Error> {
    return AnyPublisher
      .just(channel)
      .tryChannel { chan in
        let rc = ssh_channel_send_eof(self.channel)
        if rc != SSH_OK {
          throw SSHError(rc, forSession: self.client.session)
        }
        self.stdinCancellable?.cancel()
      }
      .subscribe(on: client.rloop)
      .eraseToAnyPublisher()
  }
  
  /**
   * Resize the current stream.
   */
  public func resizePty(rows: Int32, columns: Int32) -> AnyPublisher<Void, Error> {
    return AnyPublisher
      .just(channel)
      .tryChannel { chan in
        self.log.message("Resizing PTY: \(rows)x\(columns)", SSH_LOG_INFO)
        let rc = ssh_channel_change_pty_size(self.channel, columns, rows)
        if rc != SSH_OK {
          throw SSHError(rc, forSession: self.client.session)
        }
      }
      .subscribe(on: client.rloop)
      .eraseToAnyPublisher()
  }
  
  public func cancel() {
    self.log.message("Stream Cancelled", SSH_LOG_INFO)
    // Make it nil so everything associated with the flow is also disposed (self-retentions).
    stdoutCancellable = nil
    stdinCancellable = nil
    stderrCancellable = nil
  }
  
  deinit {
    print("Stream Deinit")
    self.log.message("Stream Deinit", SSH_LOG_INFO)
    self.client.closeChannel(self.channel)
  }
}

// Stream are files. We respect the API, but maybe we want to change it in the
// future, and we may not want to tie it to the particular FlowConsoleFiles intricacies.
public typealias Reader = FlowConsoleFiles.Reader
public typealias ReaderFrom = FlowConsoleFiles.ReaderFrom
public typealias Writer = FlowConsoleFiles.Writer
public typealias WriterTo = FlowConsoleFiles.WriterTo

class OutStream {
  let stream: Stream
  // Get the channel from the stream, so it is reachable as long as the Stream is.
  var channel: ssh_channel { stream.channel }
  let rloop: RunLoop
  let session: ssh_session
  var isStderr: Int32 = 0
  var currentReading: Reading?
  
  var log: SSHLogger { get { stream.log } }
  
  init(_ stream: Stream, isStderr: Bool = false) {
    self.stream = stream
    self.rloop = stream.client.rloop
    self.session = stream.client.session
    if isStderr { self.isStderr = 1 }
  }
  
  
  deinit {
    if self.isStderr == 1 {
      log.message("Errstream deinit", SSH_LOG_INFO)
    } else {
      log.message("Outstream deinit", SSH_LOG_INFO)
    }
  }
}

extension OutStream: Reader {
  // In case you try to read while the channel is closed, the operation will fail.
  // In case it did not read anything, or if the channel was closed or received an EOF while reading,
  // it will return an empty DispatchData object.
  public func read(max length: Int) -> AnyPublisher<DispatchData, Error> {
    return Reading(stream: self, length: length).publisher
      .reduce(DispatchData.empty, { prevValue, newValue -> DispatchData in
        var n = prevValue
        n.append(newValue)
        return n
      }).eraseToAnyPublisher()
  }
  
  // It is responsible to control the Reading flow. Stdout has two ways to read
  // data, for efficiency. One is through the normal loop based on demand, but the
  // other one is through the data callback, which makes sure in case the async read
  // does not have data available, that we are able to wait on it instead of
  // rescheduling the read loop.
  // This is a complex process and this object helps to get all that state into one
  // place, without polluting the parent OutStream, that could be reused for multiple read operations.
  class Reading {
    let parent: OutStream
    var channel: ssh_channel { parent.channel }
    var session: ssh_session { parent.session }
    
    var log: SSHLogger { get { parent.log }}
    
    var demand: Subscribers.Demand = .none
    let pb = PassthroughSubject<DispatchData, Error>()
    var publisher: AnyPublisher<DispatchData, Error> {
      .demandingSubject(pb,
                        receiveRequest: { demand in
                                            self.applyDemand(demand)
                                            self.readAsync() },
                        receiveCancel: { self.cancel() },
                        on: parent.rloop)
    }
    var callbacks: ssh_channel_callbacks_struct? = nil
    var bytesLeft: Int
    var bytesRead = 0
    var cancelled = false
    
    init(stream parent: OutStream, length: Int) {
      self.parent = parent
      self.bytesLeft = length
    }
    
    func applyDemand(_ demand: Subscribers.Demand) {
      if demand == .unlimited || demand == .none {
        self.demand = demand
      } else {
        self.demand = .max(self.demand.max! + demand.max!)
      }
    }
    
    func readAsync() {
      if demand == .none || cancelled == true {
        return
      }
            
      // Read max window size or data left
      let size = UInt32(min(bytesLeft, 1280000))
      let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<CUnsignedChar>.alignment)
      
      let rc = ssh_channel_read_nonblocking(self.channel, buf.baseAddress, size, parent.isStderr)
      log.message("Read \(rc) async from \(channel)", SSH_LOG_DEBUG)
      if rc == SSH_EOF || (rc == 0 && ssh_channel_is_eof(channel) != 0) {
        log.message("Received EOF on Channel", SSH_LOG_DEBUG)
        buf.deallocate()
        complete()
        return
      } else if rc == 0 {
        // Non-blocking equals to SSH_AGAIN
        buf.deallocate()
      } else if rc < 0 {
        buf.deallocate()
        pb.send(completion: .failure(SSHError(title: "Error while reading", forSession: self.session)))
        return
      } else if rc > 0 {
        // We may have received a smaller size than max
        let shrk = buf[0..<Int(rc)]
        let buffer = UnsafeRawBufferPointer(rebasing: shrk)
        let data = DispatchData(bytesNoCopy: buffer, deallocator: .custom(nil){
          buf.deallocate()
        })
        
        send(data)
      }
      
      // If we are already on EOF after that read, then complete.
      // If we still need to gather data, start the callbacks.
      // If the demand is unlimited, we assume this is a type of read that
      // won't be waiting for data, so we reschedule.
      if ssh_channel_is_eof(channel) != 0 {
        self.complete()
        return
      } else if bytesLeft > 0 {
        if demand == .unlimited {
          RunLoop.current.perform { self.readAsync() }
          return
        } else if callbacks == nil {
          if startCallbacks() != SSH_OK {
            pb.send(completion: .failure(SSHError(title: "Could not initialize callbacks.", forSession: session)))
            return
          }
        }
      }
    }
    
    func startCallbacks() -> Int32 {
      callbacks = ssh_channel_callbacks_struct()
      let ctxt = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      
      log.message("Setting up callbacks for Reading", SSH_LOG_DEBUG)
      ssh_init_channel_callbacks(&callbacks!)
      callbacks!.userdata = ctxt
      callbacks!.channel_data_function = self.hasDataCallback
      callbacks!.channel_close_function = self.channelClosingCallback
      callbacks!.channel_eof_function = self.channelEOFCallback
      
      return ssh_add_channel_callbacks(channel, &callbacks!)
    }
    
    func stopCallbacks() {
      if callbacks != nil {
        log.message("Removing callbacks for Reading", SSH_LOG_DEBUG)
        callbacks!.userdata = nil
        // When it is the same callbacks we loaded, it should not fail
        ssh_remove_channel_callbacks(channel, &callbacks!)
        callbacks = nil
      }
    }
    
    let hasDataCallback: ssh_channel_data_callback = { (session, channel, buf, length, is_stderr, userdata) -> Int32 in
      let ctxt = Unmanaged<Reading>.fromOpaque(userdata!).takeUnretainedValue()
      
      if is_stderr != ctxt.parent.isStderr {
        return 0
      }
      
      ctxt.log.message("Data callback", SSH_LOG_DEBUG)
      if length == 0 {
        return 0
      }
      
      if ctxt.demand == .none {
        ctxt.log.message("New reading window \(length)", SSH_LOG_DEBUG)
        return 0
      }
      // Fix interface on Swift
      let buf = buf!
      
      let count = min(Int(length), ctxt.bytesLeft)
      ctxt.log.message("Reading from channel \(count) out of \(length)", SSH_LOG_DEBUG)
      
      let ptBuf = UnsafeRawBufferPointer(start: buf, count: count)
      let data = DispatchData(bytes: ptBuf)
      
      ctxt.send(data)
      
      return Int32(count)
    }
    
    let channelClosingCallback: ssh_channel_close_callback = { (s, chan, userdata) in
      let ctxt = Unmanaged<Reading>.fromOpaque(userdata!).takeUnretainedValue()

      // Cannot change the state of the channel in this pass, as we are inside a callback.
      // Schedule another read and figure out what to do with the channel there.
      ctxt.log.message("Received channel close event callback", SSH_LOG_INFO)
      RunLoop.current.perform { ctxt.readAsync() }
    }
    
    let channelEOFCallback: ssh_channel_eof_callback = { (s, chan, userdata) in
      let ctxt = Unmanaged<Reading>.fromOpaque(userdata!).takeUnretainedValue()
      
      // Cannot change the state of the channel in this pass, as we are inside a callback.
      // Schedule another read and figure out what to do with the channel there.
      ctxt.log.message("Received channel EOF event callback", SSH_LOG_INFO)
      RunLoop.current.perform { ctxt.readAsync() }
    }
    
    func send(_ data: DispatchData) {
      pb.send(data)
            
      bytesRead += data.count
      log.message("Bytes Read \(bytesRead)", SSH_LOG_DEBUG)
      
      if bytesLeft != SSIZE_MAX {
        bytesLeft -= data.count
      }
      if demand != .unlimited {
        log.message("Resetting demand", SSH_LOG_DEBUG)
        demand = .none
        //demand = .max(demand.max! - 1)
      }
      
      if bytesLeft == 0 {
        complete()
      }
    }
    
    func complete() {
      log.message("Reading complete", SSH_LOG_DEBUG)
      pb.send(completion: .finished)
    }
    
    func cancel() {
      cancelled = true
    }
    
    deinit {
      stopCallbacks()
    }
  }
}
  
extension OutStream: WriterTo {
  public func writeTo(_ w: Writer) -> AnyPublisher<Int, Error> {
    return Reading(stream: self, length: SSIZE_MAX).publisher
      .flatMap(maxPublishers: .max(1)) { data in
        return w.write(data, max: data.count)
      }.eraseToAnyPublisher()
  }
}

class InStream {
  let weakStream: Stream
  var stream: Stream { weakStream }
  var channel: ssh_channel { stream.channel }
  var client: SSHClient { stream.client }
  var rloop: RunLoop { stream.client.rloop }
  var session: ssh_session { stream.client.session }
  var isClosed = false
  
  var log: SSHLogger { get { stream.log } }
  
  // Internal stream reference. Make sure the channel is not freed while
  // the components may still exist.
  init(_ stream: Stream) {
    self.weakStream = stream
  }
  
  deinit {
    self.log.message("Instream deinit", SSH_LOG_INFO)
  }
}

extension InStream: Writer {
  public func write(_ buf: DispatchData, max length: Int) ->AnyPublisher<Int, Error> {
    var cancelled = false
    let pb = PassthroughSubject<Int, Error>()
    
    // Limit buf to length before continuing
    //let buffer = buf.subdata(in: 0..<length)
    func write(_ data: DispatchData) {
      if cancelled {
        return
      }
      
      let window = ssh_channel_window_size(self.channel)
      if window == 0 {
        self.log.message("Window depleted", SSH_LOG_DEBUG)
        self.rloop.perform { write(data) }
        return
      }
      
      let size: UInt32 = min(UInt32(data.count), window)
      
      self.log.message("Trying to write \(size) with window \(window)", SSH_LOG_DEBUG)
      let rc = data.withUnsafeBytes { bytes -> Int32 in
        return ssh_channel_write(self.channel, bytes, size)
      }
      
      if rc < 0 {
        pb.send(completion: .failure(SSHError(rc, forSession: self.session)))
        return
      }
      
      pb.send(Int(rc))
      let nextData = data.subdata(in: Int(rc)..<data.count)
      
      if rc == data.count {
        pb.send(completion: .finished)
        return
      }
      
      self.rloop.perform { write(nextData) }
    }
      
    return .demandingSubject(pb,
                             receiveRequest: { _ in write(buf) },
                             receiveCancel: {
                               self.log.message("Cancelling InStream", SSH_LOG_INFO)
                               cancelled = true
                             },
                             on: rloop)
  }
}
