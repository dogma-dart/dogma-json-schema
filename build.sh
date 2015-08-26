git clone https://github.com/dogma-dart/dogma-codegen.git ../dogma-codegen
git clone https://github.com/dogma-dart/dogma-data.git -b features/simplify-serialization ../dogma-data

pub install

pub global activate linter
pub global run linter .
