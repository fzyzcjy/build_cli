// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pubviz_example.dart';

// **************************************************************************
// Generator: CliGenerator
// **************************************************************************

final _$parserForPeanutOptions = new ArgParser()
  ..addOption('format', abbr: 'f', defaultsTo: 'html', allowed: [
    'dot',
    'html'
  ], allowedHelp: <String, String>{
    'dot': 'Generate a GraphViz dot file',
    'html': 'Wrap the GraphViz dot format in an HTML template which renders it.'
  })
  ..addOption('secret', hide: true)
  ..addMultiOption('ignore-packages',
      abbr: 'i',
      help: 'A comma seperated list of packages to exclude in the output.');

PeanutOptions _$parsePeanutOptionsResult(ArgResults result) {
  T enumValueHelper<T>(String enumName, List<T> values, String enumValue) =>
      enumValue == null
          ? null
          : values.singleWhere((e) => e.toString() == '$enumName.$enumValue',
              orElse: () => throw new StateError(
                  'Could not find the value `$enumValue` in enum `$enumName`.'));

  return new PeanutOptions(
      format: enumValueHelper(
          'FormatOptions', FormatOptions.values, result['format'] as String),
      ignorePackages: result['ignore-packages'] as List<String>,
      secret: result['secret'] as String);
}

PeanutOptions parsePeanutOptions(List<String> args) {
  var result = _$parserForPeanutOptions.parse(args);
  return _$parsePeanutOptionsResult(result);
}