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
import FlowConsoleCode
import Network
import FlowConsoleConfig

import ios_system


class SharedFP {
  let service: CodeFileSystemService

  init(port: UInt16) {
    let p = NWEndpoint.Port(rawValue: port)!
    service = try! CodeFileSystemService.init(listenOn: p, tls: true, finished: { error in
      if let error = error {
        print("Listener failed - \(error)")
      }
    })
  }

  static var shared: SharedFP? = nil

  static func startedFP(port: UInt16 = 50000) -> SharedFP {
    guard let shared = shared,
          shared.service.state == .ready else {
      // We may need the WebServer to restart, instead of creating a new object.
      // My theory is that this stops, and I don't get the new state because we are in background.
      let shared = SharedFP(port: port)
      self.shared = shared
      return shared
    }

    return shared
  }
}

enum FileLocationPathOrURL {
  case fileLocationPath(FileLocationPath)
  case url(URL)

  init(_ str: String) throws {
    if str.starts(with: "http://") || str.starts(with: "https://") {
      if let url = URL(string: str) {
        self = .url(url)
      } else {
        throw ArgumentParser.ValidationError("Invalid http(s) url")
      }
    } else {
      self = .fileLocationPath(try FileLocationPath(str))
    }
  }
}

struct CodeCommand: NonStdIOCommand {
  static var configuration = CommandConfiguration(
    commandName: "code",
    abstract: "Starts code editor",
    discussion: discussion
  )
  static let discussion = """
    To connect your Code instance to the Blink File System,
    please install the blink-fs extension from the Marketplace.
    To close, use your Blink close tab shortcut (default Cmd-W).
    For more information, please read:
    https://docs.blink.sh/advanced/code
    """

  @OptionGroup var verboseOptions: VerboseOptions
  var io = NonStdIO.standard

  @Argument(
    help: "Path to connect to or http(s) vscode like editor url",
    transform: { try FileLocationPathOrURL($0) }
  )
  var pathOrUrl: FileLocationPathOrURL?

  @Option(
    help: "URL for vscode",
    transform: {
      guard let url = URL(string: $0) else {
        throw ArgumentParser.ValidationError("Invalid vscode url")
      }
      return url
    }
  )
  var vscodeURL: URL?

  mutating func run() throws {
    let session = Unmanaged<MCPSession>.fromOpaque(thread_context).takeUnretainedValue()

    var path: FileLocationPath

    try showBlinkFSWarning()

    switch pathOrUrl {
    case .url(var url):
      var str = url.absoluteString
      let githubCom = "https://github.com/"
      let codespaces = "https://github.com/codespaces/"
      if str.hasPrefix(githubCom) && !str.hasPrefix(codespaces) {
        str = "https://github.dev/" + str[githubCom.endIndex...]
        url = URL(string: str)!
      }
      let view = session.device?.view
      DispatchQueue.main.async {
        view?.addBrowserWebView(url, agent: "", injectUIO: true)
      }
      return
    case .fileLocationPath(let p):
      path = p
    default:
      // Start vscode.dev without blink-fs but with inject user IO.
      // This is useful to connect to vscode tunnels (remote server) from vscode.dev.
      let url = URL(string: "https://vscode.dev")!
      let view = session.device?.view
      DispatchQueue.main.async {
        view?.addBrowserWebView(url, agent: "", injectUIO: true)
      }
      return
    }

    let fp = SharedFP.startedFP(port: 50000)
    let port = fp.service.port

    guard let rootURI = path.codeFileSystemURI else {
      throw CommandError(message: "Could not parse path.")
    }

    let token = fp.service.registerMount(name: "xxx", root: rootURI)

    var observers: [NSObjectProtocol] = [NSObject()]
    observers[0] = NotificationCenter.default.addObserver(forName: .deviceTerminated, object: nil, queue: nil) { notification in
      guard let device = notification.userInfo?["device"] as? TermDevice
      else {
        return
      }
      if let sessionDevice = session.device, sessionDevice == device {
        fp.service.deregisterMount(token)
      }
      NotificationCenter.default.removeObserver(observers[0])
    }

    let url = vscodeURL ?? URL(string: "https://vscode.dev")!
    let agent = "BlinkSH/15 (wss;\(port);\(token))"
    let view = session.device?.view
    DispatchQueue.main.async {
      view?.addBrowserWebView(url, agent: agent, injectUIO: true)
    }
  }

  func showBlinkFSWarning() throws {
    if FileManager.default.fileExists(atPath: FlowConsolePaths.blinkCodeErrorLogURL().path, isDirectory: nil) {
      return
    }

    print(Self.discussion)
    print("Press enter to continue.")
    let _ = io.in_.readLine()
  }
}

@_cdecl("code_main")
public func code_main(argc: Int32, argv: Argv) -> Int32 {
  setvbuf(thread_stdin,  nil, _IONBF, 0)
  setvbuf(thread_stdout, nil, _IONBF, 0)
  setvbuf(thread_stderr, nil, _IONBF, 0)

  let io = NonStdIO.standard
  io.in_ = InputStream(file: thread_stdin)
  io.out = OutputStream(file: thread_stdout)
  io.err = OutputStream(file: thread_stderr)

  return CodeCommand.main(Array(argv.args(count: argc)[1...]), io: io)
}

extension FileLocationPath {
  // blinkfs:/path
  // blinksftp://user@host:port/path

  internal var codeFileSystemURI: URI? {
    if proto == .local {
      // /var/__PATH__/home/. -> /var/__PATH__/home
      let resolvedPath = (filePath as NSString).standardizingPath
      return try? URI(string: uriProtocolIdentifier +
                      resolvedPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
    } else {
      // "user@host#port" -> "user@host:port"
      guard let hostPath = hostPath else {
        return nil
      }
      let host = "/\(hostPath.replacingOccurrences(of: "#", with: ":"))"

      return try? URI(string: "\(uriProtocolIdentifier)\(host)\(filePath)")
    }
  }

  fileprivate var uriProtocolIdentifier: String {
    switch proto {
    case .local:
      // local paths do not need a domain, just the colon separator.
      // blinkfs:path/to/files
      return "blinkfs:"
    default:
      // remote paths need a domain, so we add an extra slash for the host
      // blinksftp://host/path/to
      return "blinksftp:/"
    }
  }
}
