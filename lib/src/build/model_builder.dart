// Copyright (c) 2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/build.dart';
import 'package:dogma_codegen/runner.dart';
import 'package:dogma_codegen_model/build.dart';
import 'package:dogma_source_analyzer/path.dart' as p;

import 'model_target_config.dart';
import 'schema_metadata_step.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// A [SourceBuilder] that generates model code from JSON schema files.
@RegisterBuilder('model')
class ModelBuilder extends SourceBuilder<ModelTargetConfig>
                      with SchemaMetadataStep,
                           ModelViewStep,
                           SkipViewGenerationStep,
                           ModelCodegenStep {
  //---------------------------------------------------------------------
  // Constructor
  //---------------------------------------------------------------------

  /// Creates an instance of [ModelBuilder] with the given [config].
  ModelBuilder(BuilderConfig<ModelTargetConfig> config)
      : super(config);

  //---------------------------------------------------------------------
  // AssetOutput
  //---------------------------------------------------------------------

  @override
  String filename(String input) => '${p.basenameWithoutExtension(input)}.dart';
}
