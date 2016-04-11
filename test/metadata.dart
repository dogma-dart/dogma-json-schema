// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

// \TODO Remove this file after https://github.com/dart-lang/test/issues/36 is resolved.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:test/test.dart';

import 'src/metadata/commented_test.dart' as commented_test;
import 'src/metadata/enum_metadata_test.dart' as enum_metadata_test;
import 'src/metadata/type_metadata_test.dart' as type_metadata_test;

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Entry point for tests.
void main() {
  group('Commented', commented_test.main);
  group('EnumMetadata', enum_metadata_test.main);
  group('TypeMetadata', type_metadata_test.main);
}
