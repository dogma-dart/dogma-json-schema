// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_source_analyzer/metadata.dart';
import 'package:test/test.dart';

import 'package:dogma_json_schema/metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

TypeMetadata _intType = new TypeMetadata.int();
TypeMetadata _numType = new TypeMetadata.num();
TypeMetadata _boolType = new TypeMetadata.bool();
TypeMetadata _stringType = new TypeMetadata.string();
TypeMetadata _dateTimeType = new TypeMetadata('DateTime');
TypeMetadata _uriType = new TypeMetadata('Uri');

/// Test entry point.
void main() {
  test('int', () {
    expect(typeMetadata({'type': 'integer'}), equals(_intType));
  });
  test('num', () {
    expect(typeMetadata({'type': 'number'}), equals(_numType));
  });
  test('bool', () {
    expect(typeMetadata({'type': 'boolean'}), equals(_boolType));
  });
  test('string', () {
    expect(typeMetadata({'type': 'string'}), equals(_stringType));
  });
  // Formats
  test('DateTime', () {
    var type;

    type = typeMetadata({
      'type': 'string',
      'format': 'date'
    });

    expect(type, equals(_dateTimeType));

    type = typeMetadata({
      'type': 'integer',
      'format': 'date-time'
    });

    expect(type, equals(_dateTimeType));
  });
  test('Uri', () {
    var type = typeMetadata({
      'type': 'string',
      'format': 'uri'
    });

    expect(type, equals(_uriType));
  });
}
