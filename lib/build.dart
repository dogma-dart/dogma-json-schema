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
import 'package:dogma_data/build.dart' as data;
import 'package:dogma_data/src/codegen/model_generator.dart';
import 'package:dogma_data/src/codegen/utils.dart';
import 'package:dogma_data/src/metadata/field_metadata.dart';
import 'package:dogma_data/src/metadata/model_metadata.dart';
import 'package:dogma_data/src/metadata/library_metadata.dart';
import 'package:dogma_data/src/metadata/type_metadata.dart';
import 'package:dogma_json_schema/src/json_schema.dart';
import 'package:path/path.dart' as path;

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

  var metadata = await _readMetadata(rootSchema, packageName, modelPath);

  await _writeModelLibrary(metadata, modelLibrary, modelPath, header);
  // Build the converters
  await data.build(
      args,
      packageName,
      modelLibrary,
      converters: converters,
      unmodifiableViews: unmodifiableViews,
      unmodifiableLibrary: unmodifiableLibrary,
      converterLibrary: converterLibrary,
      converterPath: converterPath,
      header: header
  );
}

Future<LibraryMetadata> _readMetadata(String root, String packageName, String modelPath) async {
  var schema = await _readJsonFile(root);
  var modelSchemas = definitions(schema);

  // \TODO Handle cases with multiple files

  var srcLibrary = libraryName(packageName, modelPath);
  var models = [];

  modelSchemas.forEach((ref, value) {
    var name = _modelName(ref);
    var snakeName = snakeCase(name);
    var libraryName = '$srcLibrary.$snakeName';
    var model = modelMetadata(name, value);

    models.add(model);
  });

  return
      new LibraryMetadata('$packageName.models', 'lib/models.dart', models: models);
}

ModelMetadata modelMetadata(String name, Map<String, Map> schema) {
  var properties = schema['properties'] as Map<String, Map>;
  var fields = new List<FieldMetadata>();

  properties.forEach((propertyName, property) {
    var type = typeMetadata(property);
    var name = camelCase(propertyName);

    fields.add(
      new FieldMetadata(
          name,
          type,
          true,
          true,
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
      var jsonType = property['type'];

      if (jsonType == 'integer') {
        type = new TypeMetadata('int');
      } else if (jsonType == 'string') {
        type = new TypeMetadata('String');
      } else if (jsonType == 'boolean') {
        type = new TypeMetadata('bool');
      } else {
        type = new TypeMetadata('Map');
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

Future<Null> _writeModelLibrary(LibraryMetadata metadata,
                                String outputPath,
                                String outputLibrariesTo,
                                String header) async
{
  // Get the directory of the outputPath so relative urls can be generated.
  var directory = path.dirname(outputPath);
  var buffer = new StringBuffer();

  buffer.writeln('import \'package:dogma_data/serialize.dart\';');

  for (var model in metadata.models) {
    buffer.writeln(generateModel(model));
  }

  var file = new File(outputPath);
  await file.writeAsString(buffer.toString());
}

Future<String> _readJsonFile(String path) async {
  var file = new File(path);
  var contents = await file.readAsString();

  return JSON.decode(contents);
}
