// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'specification.dart' as spec;

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

/// Retrieves code comments from the [schema].
///
/// In JSON Schema a code comment can be provided through the `description`
/// field. Additionally an `example` field is available to provide a sample
/// representation of the data. If an example is provided then it will be
/// converted to a markdown comment.
String comments(Map schema) {
  var description = schema[spec.description] as String ?? '';
  var example = schema[spec.example] as String ?? '';

  var buffer = new StringBuffer();

  buffer.write(description);

  if (example.isNotEmpty) {
    if (buffer.isNotEmpty) {
      // Add a line to the end of the description and a new line between the
      // description and example
      buffer.writeln('\n');
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
