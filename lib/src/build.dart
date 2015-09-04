// Copyright (c) 2015, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

library dogma_json_schema.src.build;

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:async';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/metadata.dart';
import 'package:dogma_codegen/src/build/models.dart';
import 'package:dogma_codegen/src/build/search.dart';
import 'package:logging/logging.dart';

import 'metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// The logger for the library.
final Logger _logger = new Logger('dogma_json_schema.src.build');

/// Builds the models library from the given [schema] returning the metadata
/// created from it.
///
/// \TODO MORE INFO ON WHATS GOING ON WITH schema
///
/// Additionally the [sourcePath] will be searched for any user defined
/// libraries which will be preferred over the generated equivalents.
///
/// The function will also write the resulting libraries to disk based on the
/// paths specified using the [writeUnmodifiableViews] function.
Future<LibraryMetadata> buildModels(Map<String, Map> schema,
                                    String packageName,
                                    Uri libraryPath,
                                    Uri sourcePath) async
{
  // Search for any user defined libraries
  await for (var library in findUserDefinedLibraries(sourcePath)) {
    for (var model in library.models) {
      _logger.info('Found ${model.name} in ${library.name}');
    }
  }

  // Create the equivalent library
  var models = modelsLibrary(schema, packageName, libraryPath, sourcePath);

  // Write it to disk
  await writeModels(models);

  // Return the root library
  return models;
}
