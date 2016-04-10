// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:dogma_source_analyzer/metadata.dart';

import 'specification.dart' as spec;

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

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
            type = new TypeMetadata.int();
            break;
          case 'number':
            type = new TypeMetadata.num();
            break;
          case 'boolean':
            type = new TypeMetadata.bool();
            break;
          case 'string':
            type = new TypeMetadata.string();
            break;
          case 'array':
            type = new TypeMetadata.list(typeMetadata(property[spec.items]));
            break;
          default:
            type = new TypeMetadata.map();
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
