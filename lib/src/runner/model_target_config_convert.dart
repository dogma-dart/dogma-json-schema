// Copyright (c) 2015-2016 the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Standard libraries
//---------------------------------------------------------------------

import 'dart:convert';

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_codegen/build.dart';
import 'package:dogma_codegen/runner.dart';
import 'package:dogma_convert/convert.dart';

import '../../build.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Decoder for [ModelTargetConfig]s.
class ModelTargetConfigDecoder extends Converter<Map, ModelTargetConfig>
                            implements ModelDecoder<ModelTargetConfig> {
  //---------------------------------------------------------------------
  // Member variables
  //---------------------------------------------------------------------

  /// The base decoder for [TargetConfig]s.
  final ModelDecoder<TargetConfig> targetConfigDecoder;

  //---------------------------------------------------------------------
  // Construction
  //---------------------------------------------------------------------

  /// Creates an instance of the [ModelTargetConfigDecoder].
  const ModelTargetConfigDecoder({this.targetConfigDecoder: const TargetConfigDecoder()});

  //---------------------------------------------------------------------
  // ModelDecoder
  //---------------------------------------------------------------------

  @override
  ModelTargetConfig create() => new ModelTargetConfig();

  @override
  ModelTargetConfig convert(Map input, [ModelTargetConfig model]) {
    model ??= create();

    targetConfigDecoder.convert(input, model);

    return model;
  }
}
