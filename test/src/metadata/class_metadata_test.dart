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

void _expectFieldMetadata(ClassMetadata metadata, Map properties) {
  properties.forEach((name, value) {
    var actual = classMetadataQuery/*<FieldMetadata>*/(
        metadata,
        nameMatch(camelCase(name)),
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
    expect(serialize.optional, isFalse);
  });
}

/// Test entry point.
void main() {
  test('model', () async {
    var builtin = {
      'description': 'Builtin',
      'properties': {
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
      }
    };

    var metadata = await classMetadata('Builtin', builtin);

    expect(metadata.name, 'Builtin');
    expect(metadata.comments, equalsIgnoringWhitespace(builtin['description']));

    var properties = builtin['properties'] as Map;
    expect(metadata.fields, hasLength(properties.length));
    _expectFieldMetadata(metadata, properties);
  });
  test('extends', () {

  });
  test('implements', () {

  });
}
