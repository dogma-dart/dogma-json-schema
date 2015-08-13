// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.src.json_schema;

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:async';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/codegen.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

Map<String, Map> definitions(Map schema) {
  var library = {};

  // Use the ID to get the schema
  var root = schema['id'] as String ?? '';

  // Look at the definitions
  var definitions = schema['definitions'] as Map ?? {};

  definitions.forEach((modelName, definition) {
    var schema = _getModelSchema(definition, modelName, root);

    // Add all the values
    //
    // This isn't done through the addAll method as references need to be
    // checked before adding.
    schema.forEach((path, value) {
      var current = library[path] as Map;

      if ((current == null) || current.isEmpty) {
        library[path] = value;
      }
    });
  });

  return library;
}

/// Recursive function to get the
Map<String, Map> _getModelSchema(Map schema, String modelName, String referencePath) {
  // Get the properties
  var properties = schema['properties'];

  if (properties == null) {
    return {};
  }

  var metadata = {};
  var replaceWith = {};

  // Look through the properties for references or objects that could be
  // references
  properties.forEach((fieldName, field) {
    // Look for an explicit Dart Type defined
    //
    // This is an extension for Dogma to use when a value isn't defined
    // within JSON Schema but has a specific type within the application. It
    // can also be used to avoid parsing a portion of the schema as it is
    // assumed that the dartType is defined elsewhere.
    var dartType = field['dartType'];

    if (dartType == null) {
      var type = field['type'];

      // \TODO Sanity checking for field?

      // Determine if the type is defined
      if (type == null) {
        // Verify that a reference type is there
        var ref = field['\$ref'];

        if (ref == null) {
          // \TODO Should probably throw here
        }

        // Add the reference to the definitions
        //
        // If the value starts with # then it is a local reference otherwise
        // it is defined in another schema.
        var refPath = ref.startsWith('#')
            ? '$referencePath$ref'
            : ref;

        metadata[refPath] = {};
      } else if (type == 'object') {
        var name = pascalCase(fieldName);
        var fieldSchema = _getModelSchema(field, name, referencePath);

        // Check to see if there was any schema data
        //
        // If no schema data was present then this should just be a standard
        // Map rather than a type.
        if (fieldSchema.isNotEmpty) {
          // Add all the contents of the metadata received
          metadata.addAll(fieldSchema);

          // Mark the property for replacement
          //
          // This is done because the map cannot be modified while iterating
          // through the contents.
          replaceWith[fieldName] = { '\$ref': _localReference(name, referencePath) };
        }
      }
    }
  });

  replaceWith.forEach((fieldName, value) {
    properties[fieldName] = value;
  });

  metadata['$referencePath#/definitions/$modelName'] = schema;

  return metadata;
}

String _localReference(String name, String root)
    => '$root#/definitions/$name';
