// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

// \TODO Remove this file after https://github.com/dart-lang/test/issues/36 is resolved.

/// Runs all the tests to handle code coverage generation.
library dogma_json_schema.test.all;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:test/test.dart';

import 'src/json_schema_test.dart' as json_schema_test;
import 'src/metadata_test.dart' as metadata_test;

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

void main() {
  group('JSON schema tests', json_schema_test.main);
  group('Metadata tests', metadata_test.main);
}
