// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_aws_kms_suppression.dart';

const _tracerName = 'dartastic_otel_libs_aws_kms';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an AWS KMS API call (Encrypt, Decrypt, GenerateDataKey,
/// Sign, Verify, ReEncrypt) in a CLIENT span. Never records the
/// plaintext or signed payload.
Future<T> tracedAwsKms<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? keyId,
  String? algorithm,
  String? region,
}) async {
  if (awsKmsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'rpc.system': 'aws-api',
    'rpc.service': 'KMS',
    'rpc.method': operation,
  };
  if (keyId != null) m['aws.kms.key.id'] = keyId;
  if (algorithm != null) m['aws.kms.algorithm'] = algorithm;
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    'kms $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
