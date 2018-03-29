import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';

import 'package:logging/logging.dart';

import 'package:source_gen/source_gen.dart';

import 'arg_info.dart';
import 'to_share.dart';
import 'util.dart';

final _logger = new Logger('build_cli_generator');

void warn(Object obj) => _logger.warning(obj);

class CliGenerator extends GeneratorForAnnotation<CliOptions> {
  const CliGenerator();

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, _) async {
    if (element is! ClassElement) {
      var friendlyName = friendlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }

    var classElement = element as ClassElement;

    // Get all of the fields that need to be assigned
    // TODO: We only care about constructor things + writable fields, right?
    var fieldsList = listFields(classElement);

    // Explicitly using `LinkedHashMap` – we want these ordered.
    var fields = new LinkedHashMap<String, FieldElement>.fromIterable(
        fieldsList,
        key: (f) => (f as FieldElement).name);

    // Get the constructor to use for the factory

    var buffer = new StringBuffer();

    var parserFieldName = '_\$parserFor${classElement.name}';

    buffer.writeln('''
final $parserFieldName = new ArgParser()''');

    for (var f in fields.values) {
      _parserOptionFor(buffer, f);
    }

    var resultParserName = '_\$parse${classElement.name}Result';

    buffer.writeln(''';

${classElement.name} $resultParserName(ArgResults result) {

''');

    if (fields.values.any((fe) => isEnum(fe.type))) {
      buffer.writeln(_enumValueHelper);
    }

    buffer.write('''
return ''');

    String deserializeForField(FieldElement field,
        {ParameterElement ctorParam}) {
      return _deserializeForField(field, ctorParam, fields);
    }

    var remainingFields =
        writeNewInstance(buffer, classElement, fields, deserializeForField);

    if (remainingFields.isNotEmpty) {
      warn(remainingFields);
    }

    buffer.writeln('''}
${classElement.name} parse${classElement.name}(List<String> args) {

var result = $parserFieldName.parse(args);
return $resultParserName(result);
''');

    buffer.writeln('}');

    return buffer.toString();
  }
}

const _enumValueHelper = r'''
T enumValueHelper<T>(String enumName, List<T> values, String enumValue) =>
    enumValue == null
        ? null
        : values.singleWhere((e) => e.toString() == '$enumName.$enumValue',
            orElse: () => throw new StateError(
                'Could not find the value `$enumValue` in enum `$enumName`.'));
''';

String _deserializeForField(FieldElement field, ParameterElement ctorParam,
    Map<String, FieldElement> allFields) {
  var info = ArgInfo.fromField(field);
  if (info.argType == ArgType.rest) {
    return 'result.rest';
  }

  if (info.argType == ArgType.wasParsed) {
    var name = field.name;
    assert(name.endsWith(wasParsedSuffix));
    var targetFieldName =
        name.substring(0, name.length - wasParsedSuffix.length);
    var targetField = allFields[targetFieldName];
    return "result.wasParsed('${_getArgName(targetField)}')";
  }

  var targetType = ctorParam?.type ?? field.type;
  var argName = _getArgName(field);

  var argAccess = "result['$argName']";

  if (stringChecker.isExactlyType(targetType) ||
      boolChecker.isExactlyType(targetType)) {
    return '$argAccess as ${targetType.name}';
  }

  if (isEnum(targetType)) {
    return "enumValueHelper('$targetType', $targetType.values, $argAccess as String)";
  }

  if (isMulti(targetType)) {
    return '$argAccess as List<String>';
  }

  throw new UnsupportedError('Should never get here...');
}

String _getArgName(FieldElement element) =>
    ArgInfo.fromField(element).optionData?.name ?? kebab(element.name);

void _parserOptionFor(StringBuffer buffer, FieldElement element) {
  var info = ArgInfo.fromField(element);

  switch (info.argType) {
    case ArgType.flag:
      buffer.write('..addFlag');
      break;
    case ArgType.option:
      buffer.write('..addOption');
      break;
    case ArgType.multiOption:
      buffer.write('..addMultiOption');
      break;
    case ArgType.rest:
    case ArgType.wasParsed:
      return;
  }
  buffer.write("('${_getArgName(element)}'");

  var options = info.optionData;

  if (options.abbr != null) {
    buffer.write(", abbr:'${options.abbr}'");
  }

  if (options.help != null) {
    buffer.write(", help:'${options.help}'");
  }

  if (options.defaultsTo != null) {
    buffer.write(", defaultsTo:'${options.defaultsTo}'");
  }

  if (options.allowed != null) {
    var allowedItems = options.allowed.map((e) => "'$e'").join(', ');
    buffer.write(', allowed: [$allowedItems]');
  }

  if (options.allowedHelp != null) {
    // TODO: throw/warn if there if `allowed` is null?
    var allowedHelpItems = options.allowedHelp.entries
        .map((e) => "'${e.key}':'${e.value}'")
        .join(',');
    buffer.write(', allowedHelp: <String, String>{$allowedHelpItems}');
  }

  if (options.negatable != null) {
    buffer.write(', negatable: ${options.negatable}');
  }

  if (options.hide != null) {
    buffer.write(', hide: ${options.hide}');
  }

  buffer.writeln(')');
}