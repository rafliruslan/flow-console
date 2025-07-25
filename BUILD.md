# Building
We provide you with two ways to compile and install Flow Console. This instructions will refer to assembling
a full Flow Console, compiling libraries and resources yourself. Due to the many dependencies that compose
Flow Console, this is the recommended but not shortest method.

You can also clone Flow Console and obtain a "ready to go"
tar.gz with all the dependencies as described in the ["Build" section of the README.md file](README.md#build).

## Requirements
Please note that to compile and install Flow Console in your personal
devices, you need to comply with Apple Developer Terms and Conditions,
including obtaining a Developer License for that purpose. You will also
need all the XCode command line developer tools and SDKs provided under
a separate license by Apple Inc.
- XCode > 11.0 and XCode command line tools
- Autotools for OSX

## Cloning
Clone Flow Console into your local repository and make sure to obtain any submodules:
git submodule init
git submodule update

## Dependencies & Requirements
Flow Console makes use of multiple dependencies that you have to compile
separately before building Flow Console itself. There are simple scripts available
to perform this operation.
- [Libssh2 for iOS](https://github.com/holzschu/libssh2-for-iOS); Includes OpenSSL.
- [Mosh for iOS](https://github.com/blinksh/build-mosh); Includes Protobuf.

Please note that Flow Console currently only supports armv64, so compilation for other architectures is not necessary.

### Installation
#### Libraries
The Flow Console XCode project will look for Library dependencies under the Framework folder. Libssh2 and Mosh for iOS will
also build OpenSSL and Protobuf respectively, both required to work.

To install Libssh2 and OpenSSL in your Flow Console repository, please copy
the .framework files generated on [Libssh2 for iOS](https://github.com/carloscabanero/libssh2-for-iOS) to the Framework folders.

[Mosh for iOS](https://github.com/blinksh/build-mosh) will compile both protobuf and Mosh for iOS.
After compiling, copy libmoshios.framework AND libprotobuf.a from the build-protobuf/protobuf-version/lib folder.

Flow Console also makes use of two other projects, which should be automatically downloaded using git submodule
within the same project:
- UICKeyChainStore
- MBProgressHUD

#### Resources
Flow Console makes use of a web terminal running from JavaScript code and linked at runtime. All the required
resources to bundle the app, like terminal, fonts and themes, must be included under the Resources folder.

Font Style uploads requires [webfonts.js](https://github.com/typekit/webfontloader), but it isn't
needed for Flow Console to work. Download the file and drop it into Resources folder.

Flow Console's Terminal is running from JavaScript code linked at runtime.
Most of the available open source terminals can be made to work with Flow Console,
just by providing a "write" and "signal" functions. An example of this
is provided in the Resources/term.html file. If you use another
terminal.js, edit term.html to match. We have been also successful plugging in other
terminals like [Terminal.js](http://terminal.js.org).

## Compiling
Flow Console uses a standard .xcodeproj file. Any missing files will be marked in
red, what can be used to test your installation.

To configure the project:
1. Under Targets > Flow Console > General > Identities set a unique Bundle Identifier.
2. Under Targets > Flow Console > General > Identities set your Team.
3. You might be requested to accept your profile or setup your developer account
with XCode, follow the proper Apple Developer documentation in that case.
4. If you would like to use HockeyApp, change the scheme to Flow Console Hockey, and add HockeyID with your AppID string to info.plist.

Make sure "Flow Console" is the selected Scheme for compilation. As a standard XCode project, just run it with Cmd-R.
