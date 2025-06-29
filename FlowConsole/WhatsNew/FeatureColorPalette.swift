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

import SwiftUI;
import Foundation

protocol FeatureColorPalette {
  var background: Color { get }
  var iconBackground: Color { get }
  var iconForeground: Color { get }
}

struct LightBlueColorPalette: FeatureColorPalette {
  var background: Color { Color(red: 0.99, green: 1.0, blue: 1.0) }
  var iconBackground: Color { Color(red: 0.87, green: 0.93, blue: 1.0) }
  var iconForeground: Color { Color(red: 0.09, green: 0.47, blue: 0.95) }
}

struct LightOrangeColorPalette: FeatureColorPalette {
  var background: Color { Color(red: 1, green: 0.982, blue: 0.979) }
  var iconBackground: Color { Color(red: 1, green: 0.88, blue: 0.858) }
  var iconForeground: Color { Color(red: 1.00, green: 0.27, blue: 0.13) }
}

struct LightYellowColorPalette: FeatureColorPalette {
  var background: Color { Color(red: 1, green: 0.993, blue: 0.975) }
  var iconBackground: Color { Color(red: 1, green: 0.929, blue: 0.746)}
  var iconForeground: Color { Color(red: 1.00, green: 0.72, blue: 0.00) }
}

struct LightPurpleColorPalette: FeatureColorPalette {
  var background: Color { Color(red: 0.993, green: 0.983, blue: 1) }
  var iconBackground: Color { Color(red: 0.954, green: 0.896, blue: 1)}
  var iconForeground: Color { Color(red: 0.62, green: 0.13, blue: 1.00) }
}

class DarkColorPalette: FeatureColorPalette {
  var background: Color { Color(red: 0.11, green: 0.122, blue: 0.137) }
  var iconBackground: Color { Color(red: 0.022, green: 0.033, blue: 0.042) }
  var iconForeground: Color { .white }
}

class DarkBlueColorPalette: DarkColorPalette {
  override var iconForeground: Color { LightBlueColorPalette().iconForeground }
}

class DarkOrangeColorPalette: DarkColorPalette {
  override var iconForeground: Color { LightOrangeColorPalette().iconForeground }
}

class DarkYellowColorPalette: DarkColorPalette {
  override var iconForeground: Color { LightYellowColorPalette().iconForeground }
}

class DarkPurpleColorPalette: DarkColorPalette {
  override var iconForeground: Color { LightPurpleColorPalette().iconForeground }
}
