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

import LibSSH
import OpenSSH


public enum SSHAgentRequestType: UInt8 {
  case requestIdentities = 11
  case requestSignature = 13
}

public enum SSHAgentResponseType: UInt8 {
  case failure = 5
  case success = 6
  case answerIdentities = 12
  case responseSignature = 14
}

fileprivate let errorData = Data(bytes: [0x05], count: MemoryLayout<CChar>.size)

public class SSHAgentKey {
  let constraints: [SSHAgentConstraint]?
//  var expiration: Int
  public let signer: Signer
  public let name: String

  init(_ key: Signer, named: String, constraints: [SSHAgentConstraint]? = nil) {
    self.signer = key
    self.name = named
    self.constraints = constraints
  }
}

public class SSHAgent {
  public private(set) var ring: [SSHAgentKey] = []
  // NOTE Instead of the Agent tracking the constraints, we could have a delegate for that.
  // NOTE The Agent name won't be relevant when doing Jumps between hosts, but at least you will know the first originator.
  var superAgent: SSHAgent? = nil
  var agentForward: Set<AnyCancellable> = []

  public init() {}

  private var contexts: [AgentCtxt] = []
  private class AgentCtxt {
    weak var agent: SSHAgent?
    weak var client: SSHClient?

    init(agent: SSHAgent, client: SSHClient) {
      self.agent = agent
      self.client = client
    }
  }

  public func linkTo(agent: SSHAgent) {
    self.superAgent = agent
  }

  public func attachTo(client: SSHClient) {
    let agentCtxt = AgentCtxt(agent: self, client: client)
    contexts.append(agentCtxt)
    let ctxt = UnsafeMutableRawPointer(Unmanaged.passUnretained(agentCtxt).toOpaque())
    let cb: ssh_agent_callback = { (req, len, reply, userdata) in
      // Transform to Swift types and call the request.
      let ctxt = Unmanaged<AgentCtxt>.fromOpaque(userdata!).takeUnretainedValue()
      var payload = Data(bytesNoCopy: req!, count: Int(len), deallocator: .none)
      let typeValue = SSHDecode.uint8(&payload)

      var replyData: Data
      let replyLength: Int
      // Fix types. Cannot be nil as the callback is called by the client
      guard let client = ctxt.client else {
        return 0
      }
      if let type = SSHAgentRequestType(rawValue: typeValue) {
        replyData = (try? ctxt.agent?.request(payload, context: type, client: client)) ?? errorData
        replyLength = replyData.count
      } else {
        // Return error if type is unknown
        replyData = errorData
        replyLength = errorData.count
      }

      _ = replyData.withUnsafeMutableBytes { ptr in
        ssh_buffer_add_data(reply, ptr.baseAddress!, UInt32(replyLength))
      }

      return Int32(replyData.count)
    }

    ssh_set_agent_callback(client.session, cb, ctxt)
  }

  public func loadKey(_ key: Signer, aka name: String, constraints: [SSHAgentConstraint]? = nil) {
    let cKey = SSHAgentKey(key, named: name, constraints: constraints)
    for (x, k) in ring.enumerated() {
      if cKey.name == k.name {
        // Replace the key
        ring[x] = cKey
        return
      }
    }
    ring.append(cKey)
  }

  public func removeKey(_ name: String) -> Signer? {
    if let idx = ring.firstIndex(where: { $0.name == name }) {
      let key = ring.remove(at: idx)
      return key.signer
    } else {
      return nil
    }
  }

  public func clear() {
    ring = []
  }

  func request(_ message: Data, context: SSHAgentRequestType, client: SSHClient) throws -> Data {
      switch context {
        case .requestIdentities:
          let ring = try encodedRing()
          var keys: UInt32 = UInt32(ring.count).bigEndian
          var respType = SSHAgentResponseType.answerIdentities.rawValue
          let preamble = Data(bytes: &respType, count: MemoryLayout<CChar>.size) +
            Data(bytes: &keys, count: MemoryLayout<UInt32>.size)

          return ring.reduce(preamble) { $0 + $1 }
        case .requestSignature:
          guard let signature = try encodedSignature(message, for: client) else {
            throw SSHKeyError.general(title: "Could not find proposed key")
          }
          var respType = SSHAgentResponseType.responseSignature.rawValue

          return Data(bytes: &respType, count: MemoryLayout<CChar>.size)
            + signature
//        default:
//          throw SSHKeyError.general(title: "Invalid request received")
      }
  }

  func encodedRing() throws -> [Data] {
    (try superAgent?.encodedRing() ?? []) +
      (try ring.map { (try $0.signer.publicKey.encode()) + SSHEncode.data(from: $0.name) })
  }

  func encodedSignature(_ message: Data, for client: SSHClient) throws -> Data? {

    var msg = message
    let keyBlob = SSHDecode.bytes(&msg)
    let data = SSHDecode.bytes(&msg)
    let flags = SSHDecode.uint32(&msg)

    if let signature = try superAgent?.encodedSignature(message, for: client) {
      return signature
    }

    guard let key = lookupKey(blob: keyBlob) else {
      return nil
    }

    let algorithm: String? = SigDecodingAlgorithm(rawValue: Int8(flags)).algorithm(for: key.signer)

      // Enforce constraints
    try key.constraints?.forEach {
      if !$0.enforce(useOf: key, by: client) { throw SSHKeyError.general(title: "Denied operation by constraint: \($0.name).") }
    }

    let signature = try key.signer.sign(data, algorithm: algorithm)

    return SSHEncode.data(from: signature)
  }

  fileprivate func lookupKey(blob: Data) -> SSHAgentKey? {
    // Get rid of the blob size from encode before comparing.
    ring.first { (try? $0.signer.publicKey.encode()[4...]) == blob }
  }
}

extension SSHAgent {
  func forward(to stream: Stream) {
    // Read, process and write
    // Reads up to max - it may read less if the channel closes before.
    stream.read(max: 4)
      .flatMap { data -> AnyPublisher<DispatchData, Error> in
        var payloadSizeData = data as AnyObject as! Data
        if data.count < 4 {
          return .fail(error: SSHError(title: "Agent Channel closed before read could complete"))
        }
        let payloadSize = Int(SSHDecode.uint32(&payloadSizeData))
        return stream.read(max: payloadSize)
      }
      .flatMap { data -> AnyPublisher<Int, Error> in
        var payload = data as AnyObject as! Data
        if data.count < 1 {
          return .fail(error: SSHError(title: "Agent Channel closed before read could complete"))
        }

        let typeValue = SSHDecode.uint8(&payload)

        var replyData: Data
        if let type = SSHAgentRequestType(rawValue: typeValue) {
          replyData = (try? self.request(payload, context: type, client: stream.client)) ?? errorData
        } else {
          replyData = errorData
        }

        let reply = SSHEncode.data(from: UInt32(replyData.count)) + replyData
        let dd = reply.withUnsafeBytes { DispatchData(bytes: $0) }

        return stream.write(dd, max: dd.count)
      }.sink(
        receiveCompletion: { c in
          // Completion. Log errors and escape
          if ssh_channel_is_eof(stream.channel) == 0 {
            self.forward(to: stream)
          } else {
            self.agentForward = []
          }
        }, receiveValue: { _ in }).store(in: &agentForward)
  }
}

fileprivate struct SigDecodingAlgorithm: OptionSet {
  public let rawValue: Int8
  public init(rawValue: Int8) {
    self.rawValue = rawValue
  }

  public static let RsaSha2256 = SigDecodingAlgorithm(rawValue: 1 << 1)
  public static let RsaSha2512 = SigDecodingAlgorithm(rawValue: 1 << 2)

  func algorithm(for key: Signer) -> String? {
    let type = key.sshKeyType

    if type == .rsa {
      if self.contains(.RsaSha2256) {
        return "rsa-sha2-256"
      } else if self.contains(.RsaSha2512) {
        return "rsa-sha2-512"
      }
    } else if type == .rsaCert {
      if self.contains(.RsaSha2256) {
        return "rsa-sha2-256-cert-v01@openssh.com"
      } else if self.contains(.RsaSha2512) {
        return "rsa-sha2-512-cert-v01@openssh.com"
      }
    }
    return nil
  }
}

public enum SSHEncode {
  public static func data(from str: String) -> Data {
    self.data(from: UInt32(str.count)) + (str.data(using: .utf8) ?? Data())
  }

  public static func data(from int: UInt32) -> Data {
    var val: UInt32 = UInt32(int).bigEndian
    return Data(bytes: &val, count: MemoryLayout<UInt32>.size)
  }

  public static func data(from bytes: Data) -> Data {
    self.data(from: UInt32(bytes.count)) + bytes
  }
}

public enum SSHDecode {
  static func string(_ bytes: inout Data) -> String? {
    let length = SSHDecode.uint32(&bytes)
    guard let str = String(data: bytes[0..<length], encoding: .utf8) else {
      return nil
    }
    bytes = bytes.advanced(by: Int(length))
    return str
  }

  static func bytes(_ bytes: inout Data) -> Data {
    let length = SSHDecode.uint32(&bytes)
    let d = bytes.subdata(in: 0..<Int(length))
    bytes = bytes.advanced(by: Int(length))
    return d
  }

  static func uint8(_ bytes: inout Data) -> UInt8 {
    let length = MemoryLayout<UInt8>.size
    let d = bytes.subdata(in: 0..<length)
    let value = UInt8(bigEndian: d.withUnsafeBytes { ptr in
      ptr.load(as: UInt8.self)
    })

    if bytes.count == Int(length) {
      bytes = Data()
    } else {
      bytes = bytes.advanced(by: Int(length))
    }
    return value
  }

  static func uint32(_ bytes: inout Data) -> UInt32 {
    let length = MemoryLayout<UInt32>.size
    let d = bytes.subdata(in: 0..<Int(length))
    let value = UInt32(bigEndian: d.withUnsafeBytes { ptr in
      ptr.load(as: UInt32.self)
    })

    if bytes.count == Int(length) {
      bytes = Data()
    } else {
      bytes = bytes.advanced(by: Int(length))
    }
    return value
  }
}
