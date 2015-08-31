// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.build;

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:async';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/codegen.dart';
import 'package:dogma_codegen/metadata.dart';
import 'package:dogma_codegen/path.dart';
import 'package:dogma_codegen/template.dart' as template;
import 'package:dogma_codegen/src/build/build_system.dart';
import 'package:dogma_codegen/src/build/converters.dart';
import 'package:dogma_codegen/src/build/default_paths.dart';
import 'package:dogma_codegen/src/build/parse.dart';
import 'package:dogma_codegen/src/build/models.dart';
import 'package:dogma_codegen/src/build/unmodifiable_model_views.dart';
import 'package:dogma_json_schema/src/json_schema.dart';
import 'package:logging/logging.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// The logger for the library.
final Logger _logger = new Logger('dogma_json_schema.build');

/// Builds the model, unmodifiable view, and convert libraries for the project
/// from the JSON schema specified at [schemaRoot].
///
/// This build function should be used when the models were defined without
/// the aid of any codegen.
///
/// To use in a library a build.dart file should be created in the package
/// root. This was the convention of the Dart Editor for codegen. If the editor
/// being used does not follow this convention then the
/// [build_system](https://pub.dartlang.org/packages/build_system) library can
/// be used to emulate this functionality.
///
/// An example build.dart using all the defaults follows.
///
///     import 'dart:async';
///     import 'package:dogma_codegen/build.dart';
///
///     Future<Null> main(List<String> args) async {
///       await build(args, 'my_package_name', 'path/to/schema.json');
///     }
///
/// By convention the Dogma Codegen library uses the following directory
/// structure for libraries.
///
///     package_root
///       lib
///         src
///           models
///             foo.dart
///             bar.dart
///           convert
///             foo_convert.dart
///             bar_convert.dart
///           unmodifiable_model_view
///             unmodifiable_foo_view.dart
///             unmodifiable_bar_view.dart
///         models.dart
///         convert.dart
///         unmodifiable_model_view.dart
///
/// To get the best results from the codegen process the root [modelLibrary]
/// should just export all the libraries contained in [modelPath]. All the root
/// library locations, [modelLibrary], [unmodifiableLibrary], and
/// [convertLibrary], along with the output paths, [modelPath],
/// [unmodifiablePath], and [convertPath], can be explictly set as well.
/// Deviating from the conventions should not break the codegen process, but
/// they should be followed for publicly available libraries to be consistent
/// with other clients using Dogma.
///
/// While [header] is optional it should be specified to provide any license
/// information for the generated libraries.
Future<Null> build(List<String> args,
                   String packageName,
                   String rootSchema,
                  {String modelLibrary: defaultModelLibrary,
                   String modelPath: defaultModelPath,
                   bool unmodifiable: true,
                   String unmodifiableLibrary: defaultUnmodifiableLibrary,
                   String unmodifiablePath: defaultUnmodifiablePath,
                   bool convert: true,
                   String convertLibrary: defaultConvertLibrary,
                   String convertPath: defaultConvertPath,
                   String header: ''}) async
{
  // See if a build should happen
  if (!await shouldBuild(args, [rootSchema, modelPath, unmodifiablePath, convertPath])) {
    return;
  }

  var metadata = await _readMetadata(rootSchema, packageName, modelPath);
  var exports = [];
  var libraries = {};

  for (var name in metadata.keys) {
    exports.add(_modelLibraryMetadata(name, packageName, modelPath, metadata, libraries));
  }

  var rootLibrary = new LibraryMetadata(
      libraryNameOld(packageName, modelLibrary),
      join(modelLibrary),
      exported: exports
  );

  // Set the header
  template.header = header;

  // Write the models library
  await writeModels(rootLibrary);

  // Build the unmodifiable model view library
  if (unmodifiable) {
    _logger.info('Building unmodifiable model view library');

    await buildUnmodifiableViews(
        rootLibrary,
        join(unmodifiableLibrary),
        join(unmodifiablePath)
    );
  }

  // Build the convert library
  if (convert) {
    _logger.info('Building convert library');

    await buildConverters(
        rootLibrary,
        join(convertLibrary),
        join(convertPath)
    );
  }
}

Future<Map<String, Map>> _readMetadata(String root, String packageName, String modelPath) async {
  var schema = await jsonFile(root);
  var modelSchemas = definitions(schema);

  // \TODO Handle cases with multiple files

  // The modelSchemas has the values in the form
  // "$root#/definitions/$modelName": schema.
  //
  // This converts them to the form
  // "$modelName": schema
  var models = {};

  modelSchemas.forEach((ref, value) {
    var name = _modelName(ref);

    // \TODO Sanity check models with same name, probably shouldn't happen
    models[name] = value;
  });

  return models;
}

LibraryMetadata modelsLibrary(Map<String, Map> schema,
                              String packageName,
                              String libraryPath,
                              String outputPath)
{
  var modelSchemas = definitions(schema);

  var metadata = {};

  modelSchemas.forEach((ref, value) {
    var name = _modelName(ref);

    metadata[name] = value;
  });

  var exports = [];
  var libraries = {};

  for (var name in metadata.keys) {
    exports.add(_modelLibraryMetadata(name, packageName, outputPath, metadata, libraries));
  }

  var rootLibrary = new LibraryMetadata(
      libraryNameOld(packageName, libraryPath),
      join(libraryPath),
      exported: exports
  );

  return rootLibrary;
}

LibraryMetadata _modelLibraryMetadata(String name,
                                      String packageName,
                                      String outputPath,
                                      Map<String, Map> schema,
                                      Map<String, LibraryMetadata> libraries)
{
  if (libraries.containsKey(name)) {
    return libraries[name];
  }

  var model = modelMetadata(name, schema[name]);

  // Get the dependencies
  var imports = [];

  if (model.explicitSerialization) {
    var library = new LibraryMetadata('dogma_data.serialize', Uri.parse('package:dogma_data/serialize.dart'));
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
  var fileName = '$outputPath/${snakeCase(name)}.dart';
  var uri = join(fileName);

  var library = new LibraryMetadata(
      libraryNameOld(packageName, fileName),
      uri,
      imported: imports,
      models: [model]
  );

  libraries[name] = library;

  return library;
}

ModelMetadata modelMetadata(String name, Map<String, Map> schema) {
  var properties = schema['properties'] as Map<String, Map>;
  var fields = new List<FieldMetadata>();

  properties.forEach((propertyName, property) {
    var type = typeMetadata(property);
    var name = camelCase(propertyName);
    var comments = property['description'] ?? '';

    fields.add(
      new FieldMetadata(
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
          type = new TypeMetadata('List', arguments: [typeMetadata(property['items'])]);
          break;
        default:
          type = new TypeMetadata('Map');
          break;
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
