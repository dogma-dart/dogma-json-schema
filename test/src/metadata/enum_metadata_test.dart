// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_convert/serialize.dart';
import 'package:dogma_source_analyzer/metadata.dart';
import 'package:test/test.dart';

import 'package:dogma_json_schema/metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

void _expectEnum(EnumMetadata metadata, Map schema) {
  var expectedEnumValues = schema['enum'];
  var expectedCount = expectedEnumValues.length;
  var actualEnumValues = metadata.values;

  // Expect the number of values to be the same
  expect(actualEnumValues, hasLength(expectedCount));

  // Check the fields
  var enumType = metadata.type;
  var expectedEnumNames = schema['x-enum-names'] ?? expectedEnumValues;
  var expectedEnumComments = schema['x-enum-descriptions']
      ?? new List<String>.filled(expectedCount, '');

  for (var i = 0; i < expectedCount; ++i) {
    var actual = actualEnumValues[i];

    // Should be a const field
    expect(actual.isConst, isTrue);
    // Should be a static field
    expect(actual.isStatic, isTrue);
    // Should be the same type as the enum
    expect(actual.type, equals(enumType));
    // Should have the expected field name
    expect(actual.name, expectedEnumNames[i]);
    // Should have a default value that is equal to its position in the array
    expect(actual.defaultValue, i);
    // Should have the same comments
    expect(actual.comments, equalsIgnoringWhitespace(expectedEnumComments[i]));
  }

  // Check that a comment is there
  var actualDescription = schema['description'] ?? '';

  expect(metadata.comments, equalsIgnoringWhitespace(actualDescription));

  // Check the serialize annotation
  var annotations = metadata.annotations;

  expect(annotations, hasLength(1));
  expect(annotations[0] is Serialize, isTrue);

  var serialize = annotations[0] as Serialize;
  var mapping = serialize.mapping;

  expect(mapping, isNotNull);
  expect(mapping, hasLength(expectedCount));

  for (var i = 0; i < expectedCount; ++i) {
    var value = expectedEnumValues[i];

    // Map should have a key based on the serialized value
    expect(mapping.containsKey(value), isTrue);
    // The map value should reference the index
    expect(mapping[value], i);
  }
}

/// Test entry point.
void main() {
  test('enums', () async {
    var enumeration = {
      'type': 'string',
      'enum': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'],
      'description': 'An enumeration'
    };

    var metadata = await enumMetadata('Test', enumeration);
    _expectEnum(metadata, enumeration);
  });
  test('invalid type', () {
    var wrongType = {
      'type': 'array',
      'items': {
        'type': 'string'
      },
      'enum': [['0.0'], ['1.0'], ['2.0']]
    };

    expect(
        (() async => await enumMetadata('Test', wrongType))(),
        throwsArgumentError
    );
  });
  test('x-enum-names', () async {
    var withNames = {
      'type': 'integer',
      'enum': [0, 1, 2],
      'x-enum-names': [
        'small',
        'medium',
        'large'
      ]
    };

    var metadata = await enumMetadata('Test', withNames);
    _expectEnum(metadata, withNames);

    var noNames = {
      'type': 'integer',
      'enum': [0, 1, 2]
    };

    expect(
        (() async => await enumMetadata('Test', noNames))(),
        throwsArgumentError
    );
  });
  test('x-enum-descriptions', () async {
    var withDescription = {
      'type': 'string',
      'enum': ['a', 'b', 'c'],
      'x-enum-descriptions': [
        'Comment a',
        'Comment b',
        'Comment c'
      ]
    };

    var metadata = await enumMetadata('Test', withDescription);
    _expectEnum(metadata, withDescription);
  });
}
