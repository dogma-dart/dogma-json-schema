// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.build;

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:args/args.dart';
import 'package:dogma_codegen/codegen.dart';
import 'package:dogma_codegen/metadata.dart';
import 'package:dogma_codegen/path.dart';
import 'package:dogma_codegen/template.dart' as template;
import 'package:dogma_codegen/src/build/converters.dart';
import 'package:dogma_codegen/src/build/models.dart';
import 'package:dogma_codegen/src/build/libraries.dart';
import 'package:dogma_codegen/src/build/unmodifiable_model_views.dart';
import 'package:dogma_json_schema/src/json_schema.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

Future<Null> build(List<String> args,
                   String packageName,
                   String rootSchema,
                  {String modelLibrary: 'lib/models.dart',
                   String modelPath: 'lib/src/models',
                   bool converters: true,
                   bool unmodifiableViews: true,
                   String unmodifiableLibrary: 'lib/unmodifiable_model_views.dart',
                   String unmodifiablePath: 'lib/src/unmodifiable_model_views',
                   String converterLibrary: 'lib/convert.dart',
                   String converterPath: 'lib/src/convert',
                   String header: ''}) async
{
  // Parse the arguments
  var parser = new ArgParser()
      ..addFlag('machine', defaultsTo: false)
      ..addOption('changed', allowMultiple: true)
      ..addOption('removed', allowMultiple: true);

  var parsed = parser.parse(args);

  var directory = new Directory(modelPath);

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  // Determine the caller
  //
  // If the machine flag is present then this was called by build_system and an
  // incremental build can be performed. Otherwise assume that a full rebuild
  // has been requested.
  if (parsed['machine']) {
    return;
  } else {

  }

  template.header = header;

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

  await buildModels(rootLibrary, join('lib/src/models'));

  var unmodifiablePath = join('lib/unmodifiable_model_views.dart');
  var unmodifiableSource = join('lib/src/unmodifiable_model_views');

  var test = unmodifiableModelViewsLibrary(
      rootLibrary,
      unmodifiablePath,
      unmodifiableSource
  );

  print(test);

  for (var export in test.exported) {
    print('LIBRARY');
    print(export.name);
    print(export.uri);

    print('IMPORTS');
    for (var import in export.imported) {
      print(import.name);
      print(import.uri);
    }

    print('MODELS');
    for (var model in export.models) {
      print(model.name);
    }

    print('');
  }

  await buildUnmodifiableViews(test, unmodifiablePath, unmodifiableSource);

  var convertersPath = join('lib/convert.dart');
  var convertersSource = join('lib/src/convert');

  test = convertersLibrary(rootLibrary, convertersPath, convertersSource);

  for (var export in test.exported) {
    print('LIBRARY');
    print(export.name);
    print(export.uri);

    print('IMPORTS');
    for (var import in export.imported) {
      print(import.name);
      print(import.uri);
    }

    print('CONVERTERS');
    for (var converter in export.converters) {
      print(converter.name);
    }

    print('FUNCTIONS');
    for (var function in export.functions) {
      print(function.name);
    }

    print('');
  }

  await buildConverters(test, convertersPath, convertersSource);
/*
  // Build the converters
  await data.build(
      args,
      packageName,
      modelLibrary,
      converters: converters,
      unmodifiableViews: unmodifiableViews,
      unmodifiableLibrary: unmodifiableLibrary,
      unmodifiablePath: unmodifiablePath,
      converterLibrary: converterLibrary,
      converterPath: converterPath,
      header: header
  );
  *
   */
}

Future<Map<String, Map>> _readMetadata(String root, String packageName, String modelPath) async {
  var schema = await _readJsonFile(root);
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

Future<Map> _readJsonFile(String path) async {
  var file = new File(path);
  var contents = await file.readAsString();

  return JSON.decode(contents);
}
