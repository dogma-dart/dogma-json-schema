// Copyright (c) 2016, the Dogma Project Authors.
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

import 'package:build/build.dart';
import 'package:dogma_codegen/build.dart';
import 'package:dogma_source_analyzer/metadata.dart';
import 'package:dogma_source_analyzer/path.dart' as p;

import 'model_target_config.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// An implementation of [MetadataStep] which uses a JSON schema to create the
/// metadata.
abstract class SchemaMetadataStep implements MetadataStep,
                                             AssetOutput<ModelTargetConfig> {
  //---------------------------------------------------------------------
  // MetadataStep
  //---------------------------------------------------------------------

  @override
  Future<LibraryMetadata> metadata(BuildStep buildStep) async {
    var outputId = this.outputAssetId(buildStep.input.id);

    return new LibraryMetadata(
        p.join(outputId.path),
        classes: [
          new ClassMetadata(
              'Test',
              fields: [new FieldMetadata.field('test', new TypeMetadata.string())],
              constructors: [new ConstructorMetadata(new TypeMetadata('Test'))]
          )
        ]
    );
  }
}
