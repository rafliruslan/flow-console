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

import ArgumentParser
import SSH
import ios_system


struct BlinkSSHAgentAddCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "ssh-agent",
    abstract: "Blink Default Agent Control",
    discussion: """
      You can also configure the default agent from Settings > Agent.
    """,
    version: "1.0.0"
  )

  @Flag(name: [.customShort("L")],
  help: "List keys stored on agent")
  var list: Bool = false

  @Flag(name: [.customShort("l")],
  help: "Lists fingerprints of keys stored on agent")
  var listFingerprints: Bool = false

  // Remove
  @Flag(name: [.customShort("d")],
  help: "Remove key from agent")
  var remove: Bool = false

  // Hash algorithm
  @Option(
    name: [.customShort("E")],
    help: "Specify hash algorithm used for fingerprints"
  )
  var hashAlgorithm: String = "sha256"

  // @Flag(name: [.customShort("c")],
  //       help: "Confirm before using identity"
  // )
  // var askConfirmation: Bool = false

  @Argument(help: "Key name")
  var keyName: String?

  // @Argument(help: "Agent name")
  // var agentName: String?
}

@_cdecl("fc_ssh_add")
public func fc_ssh_add(argc: Int32, argv: Argv) -> Int32 {
  let session = Unmanaged<MCPSession>.fromOpaque(thread_context).takeUnretainedValue()
  let cmd = BlinkSSHAgentAdd()
  session.registerSSHClient(cmd)
  let rc = cmd.start(argc, argv: argv.args(count: argc), session: session)
  session.unregisterSSHClient(cmd)

  return rc
}

public class BlinkSSHAgentAdd: NSObject {
  var command: BlinkSSHAgentAddCommand!

  var stdout = OutputStream(file: thread_stdout)
  var stderr = OutputStream(file: thread_stderr)
  let currentRunLoop = RunLoop.current

  public func start(_ argc: Int32, argv: [String], session: MCPSession) -> Int32 {
    do {
      command = try BlinkSSHAgentAddCommand.parse(Array(argv[1...]))
    } catch {
      let message = BlinkSSHAgentAddCommand.message(for: error)
      print(message, to: &stderr)
      return -1
    }

    guard let defaultAgent = SSHDefaultAgent.instance else {
      print("Default Agent is not available.", to: &stderr)
      return -1
    }

    if command.remove {
      let keyName = command.keyName ?? "id_rsa"
      do {
        let _ = try SSHDefaultAgent.removeKey(named: keyName)
        print("Key \(keyName) removed.", to: &stdout)
        return 0
      } catch {
        print("Couldn't remove key: \(error)", to: &stderr)
        return -1
      }
    }

    if command.list {
      for key in defaultAgent.ring {
        let str = BKPubKey.withID(key.name)?.publicKey ?? ""
        print("\(str) \(key.name)", to: &stdout)
      }

      return 0;
    }

    if command.listFingerprints {
      guard
        let alg = SSHDigest(rawValue: command.hashAlgorithm)
      else {
        print("Invalid hash algorithm \"\(command.hashAlgorithm)\"", to: &stderr)
        return -1;
      }

      for key in defaultAgent.ring {
        if let blob = try? key.signer.publicKey.encode()[4...],
           let sshkey = try? SSHKey(fromPublicBlob: blob)
        {
          let str = sshkey.fingerprint(digest: alg)

          print("\(sshkey.size) \(str) \(key.name) (\(sshkey.sshKeyType.shortName))", to: &stdout)
        }
      }
      return 0
    }

    // Default case: add key
    do {
      try SSHDefaultAgent.addKey(named: command.keyName ?? "id_rsa")
      return 0
    } catch {
      print("Could not add key \(error)", to: &stderr)
      return -1;
    }
  }
}
