// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.src.metadata;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/identifier.dart';
import 'package:dogma_codegen/metadata.dart';
import 'package:dogma_codegen/path.dart';
import 'package:dogma_codegen/src/build/libraries.dart';
import 'package:logging/logging.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// The logger for the library.
final Logger _logger = new Logger('dogma_json_schema.src.metadata');

LibraryMetadata modelsLibrary(Map<String, Map> schema,
                              String packageName,
                              Uri libraryPath,
                              Uri outputPath)
{
  var metadata = new Map<String, Map>();

  schema.forEach((ref, value) {
    var name = _modelName(ref);

    metadata[name] = value;
  });

  var exports = [];
  var libraries = {};

  for (var name in metadata.keys) {
    exports.add(_modelLibraryMetadata(name, packageName, outputPath, metadata, libraries));
  }

  var rootLibrary = new LibraryMetadata(
      libraryName(packageName, libraryPath),
      libraryPath,
      exported: exports
  );

  return rootLibrary;
}

LibraryMetadata _modelLibraryMetadata(String name,
                                      String packageName,
                                      Uri outputPath,
                                      Map<String, Map> schema,
                                      Map<String, LibraryMetadata> libraries)
{
  if (libraries.containsKey(name)) {
    _logger.finer('Found library with $name');
    return libraries[name];
  }

  var model = modelMetadata(name, schema[name]);

  // Get the dependencies
  var imports = [];

  if (model.explicitSerialization) {
    _logger.finer('Model requires explicit serialization');
    var library = dogmaSerialize;
    imports.add(library);
  }

  for (var dependency in modelDependencies(model)) {
    var dependencyName = dependency.name;

    // Verify that the dependency is within the schema
    if (schema.containsKey(dependencyName)) {
      imports.add(_modelLibraryMetadata(dependency.name, packageName, outputPath, schema, libraries));
    }
  }

  // Create the library
  var uri = join('${pascalToSnakeCase(name)}.dart', base: outputPath);

  var library = new LibraryMetadata(
      libraryName(packageName, uri),
      uri,
      imported: imports,
      models: [model]
  );

  _logger.info('Creating library ${library.name} at ${library.uri}');

  libraries[name] = library;

  return library;
}

ModelMetadata modelMetadata(String name, Map<String, Map> schema) {
  _logger.info('Creating model $name');

  var properties = schema['properties'] as Map<String, Map>;
  var fields = new List<SerializableFieldMetadata>();

  properties.forEach((propertyName, property) {
    var type = typeMetadata(property);
    print(propertyName);
    var name = camelCase(propertyName);
    var comments = property['description'] ?? '';

    _logger.fine('Adding field $name of type ${type.name}');

    fields.add(
        new SerializableFieldMetadata(
            name,
            type,
            true,
            true,
            comments: comments,
            serializationName: propertyName)
    );
  });

  return new ModelMetadata(name, fields);
}

TypeMetadata typeMetadata(Map property) {
  var dartType = property['dartType'] as String;
  var type;

  if (dartType == null) {
    // See if the value is a reference
    var ref = property['\$ref'] as String;

    if (ref == null) {
      // Check the format first
      //
      // The format can contain a more explicit type for the metadata than
      // what is present in 'type'. For example a DateTime will often be of
      // 'type' string.
      var format = property['format'];

      if (format != null) {
        switch (format) {
          case 'date':
          case 'date-time':
            type = new TypeMetadata('DateTime');
            break;
          case 'uri':
            type = new TypeMetadata('Uri');
            break;
        }
      }

      // Check the type next
      if (type == null) {
        switch (property['type']) {
          case 'integer':
            type = new TypeMetadata('int');
            break;
          case 'number':
            type = new TypeMetadata('num');
            break;
          case 'boolean':
            type = new TypeMetadata('bool');
            break;
          case 'string':
            type = new TypeMetadata('String');
            break;
          case 'array':
            type = new TypeMetadata(
                'List', arguments: [typeMetadata(property['items'])]);
            break;
          default:
            type = new TypeMetadata('Map');
            break;
        }
      }
    } else {
      type = new TypeMetadata(_modelName(ref));
    }
  } else {
    type = new TypeMetadata(dartType);
  }

  return type;
}

String _modelName(String path) {
  var lastIndex = path.lastIndexOf('/');

  return path.substring(lastIndex + 1);
}
