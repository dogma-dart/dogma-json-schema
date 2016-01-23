// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.test.src.metadata_test;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/metadata.dart';
import 'package:dogma_codegen/path.dart';
import 'package:dogma_codegen/src/build/parse.dart';
import 'package:dogma_codegen/src/build/logging.dart';
import 'package:dogma_json_schema/src/metadata.dart';
import 'package:dogma_json_schema/src/json_schema.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'address_check.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Test entry point.
void main() {
  initializeLogging(Level.ALL);

  test('Definitions', () async {
    var schema = await jsonFile('test/schemas/definitions.json');

    var library = <String, Map>{};
    definitions(schema, library);

    var models = modelsLibrary(
        library,
        'schemas',
        join('models.dart'),
        join('src/models')
    );

    var address = findModel(models, 'Address');
    expect(address, isNotNull);
    expectAddressModel(address);
  });
}
