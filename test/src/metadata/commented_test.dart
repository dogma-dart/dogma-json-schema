// Copyright (c) 2015-2016, the Dogma Project Authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a zlib license that can be found in
// the LICENSE file.

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'package:test/test.dart';

import 'package:dogma_json_schema/metadata.dart';

//---------------------------------------------------------------------
// Library contents
//---------------------------------------------------------------------

const String _descriptionValue = 'This is a description';
const String _exampleValue = '''{
  "foo": 2
}''';
final Map _description = {'description': _descriptionValue};
final Map _example = {'example': _exampleValue};
final Map _both = new Map.from(_description)..addAll(_example);

void _expectMarkdown(String value, [int fromLine = 0]) {
  var split = value.split('\n');
  var splitCount = split.length;

  // String will always end in an empty line so ignore the last one
  for (var i = fromLine; i < splitCount - 1; ++i) {
    expect(split[i], startsWith('    '));
  }
}

/// Test entry point.
void main() {
  test('description', () {
    expect(comments({}), isEmpty);
    expect(comments(_description), equalsIgnoringWhitespace(_descriptionValue));
  });
  test('example', () {
    var example = comments(_example);
    var exampleLines = _exampleValue.split('\n').length;

    expect(example, equalsIgnoringWhitespace(_exampleValue));
    expect(example.split('\n'), hasLength(exampleLines + 1));
    _expectMarkdown(example);

    var both = comments(_both);
    var bothSplit = both.split('\n');

    expect(bothSplit, hasLength(2 + exampleLines + 1));
    expect(bothSplit[0], equals(_descriptionValue));
    expect(bothSplit[1], isEmpty);
    _expectMarkdown(both, 2);
  });
}
