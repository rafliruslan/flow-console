# Flow Console for iOS

Flow Console is a professional, desktop-grade terminal for iOS that leverages the support of Mosh and SSH. Providing stable connections, lightning-fast speeds, and full configurations for your all-day-long development workflow.

Flow Console was built as a professional grade product from the onset, grounded on these three concepts:

- **Fast rendering**: dmesg in your Unix server should be instantaneous. We use Chromium's HTerm to ensure that rendering is perfect and fast, even with special, tricky encodings.
- **Always on**: Mosh transcends SSH's variability. Mosh overcomes the unstable and intermittent connectivity that we all associate with mobile connections. You can seamlessly jump from home, to the train, and then the office thanks to Mosh.
- **Fully configurable**: Flow Console embraces Bluetooth-coupled keyboards with gusto. Configure Caps as Esc on Vim, or Caps as Ctrl on Emacs. Add your own custom themes and fonts to Flow Console.

## Features

- **Command-focused interface**: Jump right into a friendly shell with a clear, straightforward interface
- **Full screen terminal**: No menus, just your terminal
- **Gesture controls**: Swipe to move between connections, slide down to close them, and pinch to zoom
- **Configuration management**: Add your own Hosts and RSA Encryption keys
- **SplitView support**: For necessary searches and chats with coworkers

## Built-in Shell Utilities

Flow Console includes a comprehensive set of shell utilities:

**File Operations:**
- cd, setenv, ls, touch, cp, rm, ln, mv, mkdir, rmdir
- df, du, chksum, chmod, chflags, chgrp, stat, readlink
- compress, uncompress, gzip, gunzip

**System Information:**
- pwd, env, printenv, date, uname, id, groups, whoami, uptime

**Text Processing:**
- cat, grep, wc

**Network & File Transfer:**
- curl (includes http, https, scp, sftp...), scp, sftp
- tar

**Scripting:**
- Python and Lua scripting support
- Redirection support (">", "<", "&>")

All commands are provided by the `ios_system.framework`. For more information about extending commands, see: https://github.com/holzschu/ios_system.

### File Transfer Examples

```bash
# Using curl with key management
curl scp://host.name.edu/filename -o filename --key $SHARED/id_rsa --pass MyPassword 

# Using scp and sftp commands
scp user@host.name.edu:filename . 
sftp localFilename user@host.name.edu:~/ 
```

## Environment Variables

Due to iOS sandbox restrictions, you can only write in `~/Documents/`, `~/Library/` and `~/tmp`. Flow Console sets up the following environment variables:

```bash
PATH = $PATH:~/Library/bin:~/Documents/bin
PYTHONHOME = $HOME/Library/
SSH_HOME = $HOME/Documents/
CURL_HOME = $HOME/Documents/
HGRCPATH = $HOME/Documents/.hgrc/
SSL_CERT_FILE = $HOME/Documents/cacert.pem
```

## Building Flow Console

### Prerequisites

1. Check that `xcode-select -p` points to Xcode.app (`/Applications/Xcode.app/Contents/Developer`)

### Build Steps

1. Clone and setup the repository:
```bash
git clone --recursive https://github.com/your-username/flow-console.git && \
    cd flow-console && ./get_frameworks.sh && ./get_resources.sh && \
    rm -rf "Flow Console.xcodeproj/project.xcworkspace/xcshareddata/"
```

2. Configure developer settings:
```bash
cp template_setup.xcconfig developer_setup.xcconfig
```
Edit `developer_setup.xcconfig` to set your Apple Developer ID and other settings.

3. Open `Flow Console.xcodeproj` in Xcode

4. **Optional**: If building without iCloud, Push Notifications, or Keychain sharing, disable these capabilities in the project settings.

5. Connect your iOS device and select it in Product → Destination

6. Build and run the project

### Device Testing

To build for a connected iPad Pro 11-inch:
```bash
xcodebuild -project "Flow Console.xcodeproj" \
  -scheme "Flow Console" \
  -destination "platform=iOS,name=iPad Pro (11-inch)" \
  clean build
```

## Contributing

Flow Console is free and open source software. We welcome contributions!

- **Bug Reports**: Please report bugs here on GitHub
- **Feature Requests**: Open an issue to discuss new features
- **Pull Requests**: Contributions are welcome following our coding standards

## License

Flow Console is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Flow Console is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Flow Console. If not, see <http://www.gnu.org/licenses/>.

## Acknowledgments

Flow Console is based on the open source Blink Shell project. We thank the original developers for creating a solid foundation for terminal applications on iOS.