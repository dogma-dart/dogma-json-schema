// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.test.src.json_schema_test;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/src/build/parse.dart';
import 'package:dogma_json_schema/src/json_schema.dart';
import 'package:test/test.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Test entry point.
void main() {
  test('Definitions', () async {
    var schema = await jsonFile('test/schemas/definitions.json');

    var library = <String, Map>{};
    definitions(schema, library);

    library.forEach((key, value) {
      print(key);
      print(value);
    });

    expect(true, true);
  });
}
