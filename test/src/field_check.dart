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

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

void expectField(ModelMetadata metadata,
                 String fieldName,
                 String fieldType,
                {bool optional: false,
                 bool encode: true,
                 bool decode: true,
                 dynamic defaultsTo: null})
{
  var field = findFieldByName(metadata, fieldName);
  expect(field, isNotNull);
  expect(field.name, fieldName);
  expect(field.type.name, fieldType);
  expect(field.optional, optional);
  expect(field.encode, encode);
  expect(field.decode, decode);
  //expect(field.defaultsTo, defaultsTo);
}
