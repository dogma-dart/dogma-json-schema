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

import 'package:dogma_codegen/identifier.dart';
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
    new Logger('dogma_json_schema.src.metadata.class_metadata');

/// Creates a class with the given [name] from the values in the [schema].
Future<ClassMetadata> classMetadata(String name, Map schema) async {
  var allOf = schema[spec.allOf] as List<Map>;
  var hasInheritance = allOf != null;
  var properties;

  // Find the properties
  if (hasInheritance) {
    properties = {};

    for (var value in allOf) {
      var subSchemaProperties = value[spec.properties] as Map;

      if (subSchemaProperties != null) {
        properties.addAll(subSchemaProperties);
      }
    }
  } else {
    properties = schema[spec.properties] as Map;
  }

  // Get the required properties
  //
  // If required properties are not specified it is assumed that all fields are
  // required
  var requiredProperties = schema[spec.required] as List<String> ?? <String>[];
  var allPropertiesRequired = requiredProperties.isEmpty;
  var fields = <FieldMetadata>[];

  // Iterate over the properties creating the fields
  properties.forEach((propertyName, subSchema) {
    // Get the type of the field
    var fieldType = typeMetadata(subSchema);

    // Get the name of the field
    //
    // Either use the explicitly specified name or the property name converted
    // into camel case
    var fieldName = subSchema[spec.fieldName] ?? camelCase(propertyName);

    // Determine if the field is required
    var required =
        allPropertiesRequired || requiredProperties.contains(fieldName);

    // Create the serialize annotation
    var serialize = new Serialize.field(propertyName, optional: !required);

    fields.add(new FieldMetadata.field(
        fieldName,
        fieldType,
        comments: comments(subSchema),
        annotations: [serialize]
    ));
  });

  return new ClassMetadata(name, fields: fields, comments: comments(schema));
}
