// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.test.src.metadata_test;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/metadata.dart';
import 'package:test/test.dart';

import 'field_check.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Verifies the address [metadata].
void expectAddressModel(ModelMetadata metadata) {
  expect(metadata.name, 'Address');

  // Required fields
  expectField(metadata, 'locality', 'String');
  expectField(metadata, 'region', 'String');
  expectField(metadata, 'countryName', 'String');

  // Optional fields
  expectField(metadata, 'postOfficeBox', 'String', optional: true, defaultsTo: '');
  expectField(metadata, 'extendedAddress', 'String', optional: true, defaultsTo: '');
  expectField(metadata, 'streetAddress', 'String', optional: true, defaultsTo: '');
  expectField(metadata, 'postalCode', 'String', optional: true, defaultsTo: '');
}
