# Dogma JSON Schema
> Generates models from JSON schemas. 

[![Join the chat at https://gitter.im/dogma-dart/dogma-dart.github.io](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/dogma-dart/dogma-dart.github.io?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](http://beta.drone.io/api/badges/dogma-dart/dogma-json-schema/status.svg)](http://beta.drone.io/dogma-dart/dogma-json-schema)
[![Coverage Status](https://coveralls.io/repos/dogma-dart/dogma-json-schema/badge.svg?branch=master&service=github)](https://coveralls.io/github/dogma-dart/dogma-json-schema?branch=master)

## Usage

Dogma JSON Schema uses the [Dogma Codegen](https://github.com/dogma-dart/dogma-codegen) library to generate model data
for a library. It can also generate unmodifiable model views for immutability as well as converters to handle
serialization to and from Map data.

The Dogma JSON Schema library is used by [Dogma Swagger](https://github.com/dogma-dart/dogma-swagger) and
[Dogma RAML](https://github.com/dogma-dart/dogma-raml). If a full RESTful API has been described in either of those
formats then the corresponding library should be used instead of Dogma JSON Schema. Dogma JSON Schema is typically
meant for cases where just a file format is being described.

To use create a `build.dart` file in the root of the project. This file can either be run manually, which will trigger
a full rebuild of the library, or run when files are changed using the
[build_system](https://github.com/a14n/build_system.dart) library.

```dart
import 'dart:async';
import 'package:dogma_json_schema/build.dart';

Future<Null> main(List<String> args) async {
  await build(
      args,
      'my_package_name', // The name of the package within the pubspec
      'lib/models.json'  // The path to the root JSON schema
  );
}
```
By default the `build` function will create unmodifiable model views as well as converters. See the documentation of
[build](#) for the full options available from the `build` function. For additional information on how the unmodifiable
model views and converters are generated see the documentation of
[Dogma Codegen](https://github.com/dogma-dart/dogma-codegen).

## JSON Schema Extensions

Dogma JSON Schema contains additional fields that can be used to control the code generated off of a schema. These
fields are all optional and should only be used when necessary.

### Model generation

### x-dart-type

The `x-dart-type` value is used to specify a type that isn't present in the JSON schema format. This can be used to
specify types outside of the models described in the

As an example the following uses `x-dart-type` to specify that the value of `time` is a `DateTime` within the model
definition.

```json
{
  "Appointment": {
    "properties": {
      "name": {
        "description":"The name of the appointment",
        "type":"string"
      },
      "time": {
        "description":"When the appointment begins",
        "type":"integer",
        "format":"int64",
        "x-dart-type":"DateTime"
      }
    }
  }
}
```

This will generate the following definition.

```dart
library my_library.src.models.appointment;

class Appointment {
  /// When the appointment begins
  DateTime time;
  /// The name of the appointment
  String name;
}
```

When using this field a function to (de)serialize the value needs to be provided. See the documentation of
[Dogma Codegen](https://github.com/dogma-dart/dogma-codegen) for information on specifying custom converters.

### Enumeration generation

#### x-enum-names

The `x-enum-names` value is used to override the generated names. If you have an enumeration whose values are not
strings then this field is required.

```json
{
  "definitions": {
    "ImageSize": {
      "description": "The size of the image to retrieve",
      "type": "string",
      "enum": [
        "s",
        "m",
        "l"
      ],
      "x-enum-names": [
        "small",
        "medium",
        "large"
      ]
    }
  }
}
```

This will generate the following definition.

```dart
library my_library.src.models.image_size;

import 'package:dogma_data/serialize.dart';

/// The size of the image.
@Serialize.values(const {
  's': ImageSize.small,
  'm': ImageSize.medium,
  'l': ImageSize.large
})
enum ImageSize { small, medium, large }

```
#### x-enum-descriptions

The `x-enum-descriptions` value allows individual enum values to contain code comments.

```json
{
  "definitions": {
    "AddressType": {
      "type": "string",
      "enum": [
        "residential",
        "business"
      ],
      "x-enum-descriptions": [
        "A home address.",
        "The address of a business."
      ]
    }
  }
}
```
This will generate the following definition.

```dart
library my_library.src.models.address_type;

enum AddressType {
  /// A home address.
  residential,
  /// The address of a business.
  business
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dogma-dart/dogma-json-schema/issues
