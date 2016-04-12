// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/identifier.dart';
import 'package:dogma_convert/serialize.dart';
import 'package:dogma_source_analyzer/matcher.dart';
import 'package:dogma_source_analyzer/metadata.dart';
import 'package:dogma_source_analyzer/query.dart';
import 'package:test/test.dart';

import 'package:dogma_json_schema/metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

void _expectFieldMetadata(ClassMetadata metadata,
                          Map properties,
                         {List<String> requiredFields}) {
  requiredFields ??= <String>[];

  properties.forEach((name, value) {
    var expectedName = value['x-field-name'] ?? camelCase(name);

    var actual = classMetadataQuery/*<FieldMetadata>*/(
        metadata,
        nameMatch(expectedName),
        includeFields: true
    ) as FieldMetadata;

    expect(actual, isNotNull);
    expect(actual.comments, equalsIgnoringWhitespace(value['description']));

    var annotations = actual.annotations;
    expect(annotations, hasLength(1));
    expect(annotations[0] is Serialize, isTrue);

    var serialize = annotations[0] as Serialize;
    expect(serialize.name, name);
    expect(serialize.encode, isTrue);
    expect(serialize.decode, isTrue);

    var required = requiredFields.isEmpty || requiredFields.contains(name);
    expect(serialize.optional, equals(!required));
  });
}

final Map _builtinProperties = {
  'anInt': {
    'description': 'An int',
    'type': 'integer'
  },
  'a-bool': {
    'description': 'A bool',
    'type': 'boolean'
  },
  'a_number': {
    'description': 'A number',
    'type': 'number'
  }
};

/// Test entry point.
void main() {
  test('model', () async {
    var builtin = {
      'description': 'Builtin',
      'properties': _builtinProperties
    };

    var metadata = await classMetadata('Builtin', builtin);

    expect(metadata.name, 'Builtin');
    expect(metadata.comments, equalsIgnoringWhitespace(builtin['description']));

    var properties = builtin['properties'] as Map;
    expect(metadata.fields, hasLength(properties.length));
    _expectFieldMetadata(metadata, properties);
  });
  test('required fields', () async {
    var builtin = {
      'description': 'Builtin',
      'properties': _builtinProperties,
      'required': ['anInt']
    };

    var metadata = await classMetadata('Builtin', builtin);

    expect(metadata.name, 'Builtin');
    expect(metadata.comments, equalsIgnoringWhitespace(builtin['description']));

    var properties = builtin['properties'] as Map;
    expect(metadata.fields, hasLength(properties.length));
    _expectFieldMetadata(
        metadata,
        properties,
        requiredFields: builtin['required'] as List<String>
    );
  });
  test('extends', () {

  });
  test('implements', () async {
    var implements = {
      'description': 'Builtin',
      'allOf': [
        // Additional properties
        {'properties': _builtinProperties}
      ]
    };

    var metadata = await classMetadata('Implements', implements);

    expect(metadata.name, 'Implements');
    expect(metadata.comments, equalsIgnoringWhitespace(implements['description']));

    var allOf = implements['allOf'] as List<Map>;
    var properties = allOf[0]['properties'] as Map;
    expect(metadata.fields, hasLength(properties.length));
    _expectFieldMetadata(metadata, properties);

  });

  // Extension tests

  test('x-field-name', () async {
    var explicitFieldNames = {
      'description': 'Explicit field names',
      'properties': {
        'a-bool': {
          'description': 'A bool',
          'type': 'boolean',
          'x-field-name': 'longWindedFieldName'
        }
      }
    };

    var metadata = await classMetadata('Builtin', explicitFieldNames);

    expect(metadata.name, 'Builtin');
    expect(metadata.comments, equalsIgnoringWhitespace(explicitFieldNames['description']));

    var properties = explicitFieldNames['properties'] as Map;
    expect(metadata.fields, hasLength(properties.length));
    _expectFieldMetadata(metadata, properties);
  });
}
