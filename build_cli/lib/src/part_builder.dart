// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'build_cli_generator.dart';

Builder cliPartBuilder({String header}) {
  return new PartBuilder(
    const [
      const CliGenerator(),
    ],
    header: header,
  );
}
