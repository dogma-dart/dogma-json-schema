// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:async';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_convert/serialize.dart';
import 'package:dogma_source_analyzer/metadata.dart';
import 'package:logging/logging.dart';

import 'commented.dart';
import 'specification.dart' as spec;
import 'type_metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// The logger for the library
final Logger _logger =
    new Logger('dogma_json_schema.src.metadata.enum_metadata');

/// Creates an enumeration with the given [name] from the values in the
/// [schema].
///
/// The `x-enum-names` value is used to override the generated names. If the
/// enumeration's values is not a string then this field is required.
///
///     {
///       "type": "integer"
///       "enum": [ 0, 1, 2 ]
///       "x-enum-names": [ "small, "medium", "large"
///     }
///
/// The `x-enum-descriptions` value allows individual enum values to contain
/// code comments.
///
///     {
///       "type": "string",
///       "enum": [
///         "residential",
///         "business"
///       ],
///       "x-enum-descriptions": [
///         "A home address."
///         "The address of a business."
///       ]
///     }
Future<EnumMetadata> enumMetadata(String name, Map<String, Map> schema) async {
  _logger.info('Creating enum $name');

  // Get the enumeration names
  var names = schema[spec.enumNames] as List<String> ?? <String>[];
  var explicitNames = names.isNotEmpty;

  // Get the type for the fields
  var fieldType = typeMetadata(schema);

  // Verify the enum's type
  if (!fieldType.isString) {
    // Only supporting strings or numbers as enum
    if (!fieldType.isNum) {
      throw new ArgumentError.value(schema, 'Enum type is not a string or number');
    }

    // Explicit naming is required for anything other than strings
    if (!explicitNames) {
      throw new ArgumentError.value(schema, 'Enum type is not string and no names are provided');
    }
  }

  // Get the enumeration values
  var values = schema[spec.enumeration] as List;
  var valueCount = values.length;

  // Get the descriptions
  var descriptions = schema[spec.enumDescriptions] as List<String>
      ?? new List<String>.filled(valueCount, '');

  // Create the fields and mapping
  var fields = <FieldMetadata>[];
  var mapping = {};
  var enumType = new TypeMetadata(name);

  for (var i = 0; i < valueCount; ++i) {
    var value = values[i];

    // Get the name
    var name = explicitNames ? names[i] : value;

    // Create the mapping
    //
    // The mapping internally is `value`: `name` where name is stored
    // internally as the index of the enumeration.
    mapping[value] = i;

    // Create the field
    fields.add(new FieldMetadata.field(
       name,
       enumType,
       isStatic: true,
       isConst: true,
       defaultValue: i,
       comments: descriptions[i]
    ));
  }

  // Return the enumeration
  return new EnumMetadata(
      name,
      fields,
      annotations: [new Serialize.values(mapping)],
      comments: comments(schema)
  );
}
