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

import 'specification.dart' as spec;

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

  var exports = <LibraryMetadata>[];
  var libraries = <String, LibraryMetadata>{};

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

  var imports = new List<LibraryMetadata>();
  var classes = new List<ClassMetadata>();

  var modelSchema = schema[name] as Map<String, Map>;

  if (!modelSchema.containsKey(spec.enumeration)) {
    var model = modelMetadata(name, modelSchema);

    if (model.explicitSerialization) {
      _logger.finer('Model requires explicit serialization');
      imports.add(dogmaSerialize);
    }

    for (var dependency in modelDependencies(model)) {
      var dependencyName = dependency.name;

      // Verify that the dependency is within the schema
      if (schema.containsKey(dependencyName)) {
        imports.add(_modelLibraryMetadata(dependency.name, packageName, outputPath, schema, libraries));
      }
    }

    classes.add(model);
  } else {
    var enumeration = enumMetadata(name, modelSchema);

    if (enumeration.explicitSerialization) {
      _logger.finer('Enumeration requires explicit serialization');
      imports.add(dogmaSerialize);
    }

    classes.add(enumeration);
  }

  // Create the library
  var uri = join('${pascalToSnakeCase(name)}.dart', base: outputPath);

  var library = new LibraryMetadata(
      libraryName(packageName, uri),
      uri,
      imported: imports,
      classes: classes
  );

  _logger.info('Creating library ${library.name} at ${library.uri}');

  libraries[name] = library;

  return library;
}

ModelMetadata modelMetadata(String name, Map<String, Map> schema) {
  _logger.info('Creating model $name');

  var properties = schema[spec.properties] as Map<String, Map>;
  var requiredFields = schema[spec.required] as List<String>?? <String>[];
  var fields = new List<SerializableFieldMetadata>();

  properties.forEach((propertyName, property) {
    var type = typeMetadata(property);
    var name = camelCase(propertyName);
    var comments = _comments(property);
    var required = requiredFields.isEmpty || requiredFields.contains(propertyName);
    var defaultsTo;

    _logger.fine('Adding field $name of type ${type.name}');

    fields.add(
        new SerializableFieldMetadata(
            name,
            type,
            true,
            true,
            comments: comments,
            serializationName: propertyName,
            optional: !required,
            defaultsTo: defaultsTo
        )
    );
  });

  var classComments = _comments(schema);

  return new ModelMetadata(name, fields, comments: classComments);
}

/// Creates metadata for an enumeration with the given [name] defined by the
/// value of [schema].
EnumMetadata enumMetadata(String name, Map<String, Map> schema) {
  _logger.info('Creating enum $name');
  // \TODO Sanity check based on type?? Currently assuming string

  var values = (schema[spec.enumNames] ?? []) as List<String>;
  var encoded = <String>[];
  var enums = schema['enum'] as List<String>;

  if (values.isEmpty) {
    for (var value in enums) {
      values.add(camelCase(value));
      encoded.add(value);
    }
  } else {
    for (var value in enums) {
      encoded.add(value);
    }
  }

  var valueComments = schema[spec.enumDescriptions] as List<String>
      ?? new List<String>.filled(values.length, '');

  var comments = _comments(schema);

  return new EnumMetadata(
      name,
      values,
      encoded: encoded,
      comments: comments,
      valueComments: valueComments
  );
}

/// Creates type metadata for the given [property] field.
TypeMetadata typeMetadata(Map property) {
  var dartType = property[spec.dartType] as String;
  var type;

  if (dartType == null) {
    // See if the value is a reference
    var ref = property[spec.reference] as String;

    if (ref == null) {
      // Check the format first
      //
      // The format can contain a more explicit type for the metadata than
      // what is present in 'type'. For example a DateTime will often be of
      // 'type' string.
      var format = property[spec.format];

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
        switch (property[spec.type]) {
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
                'List', arguments: [typeMetadata(property[spec.items])]);
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

/// Adds comments for the metadata using the [description] and [example].
String _comments(Map schema) {
  var description = schema[spec.description] as String ?? '';
  var example = schema[spec.example] as String ?? '';

  var buffer = new StringBuffer();

  buffer.write(description);

  if (example.isNotEmpty) {
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }

    example = example.trim();

    // Split the example into lines so markdown code blocks can be added
    for (var line in example.split('\n')) {
      buffer.write('    ');
      buffer.writeln(line);
    }
  }

  return buffer.toString();
}
