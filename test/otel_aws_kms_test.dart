// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_aws_kms/otel_aws_kms.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_aws_kms-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Decrypt records CLIENT span', () async {
    await tracedAwsKms<String>(
      operation: 'Decrypt',
      keyId: 'arn:aws:kms:us-east-1:123:key/abc',
      algorithm: 'SYMMETRIC_DEFAULT',
      region: 'us-east-1',
      invoke: () async => 'plaintext-redacted',
    );
    final a = attrsOf(spans.findSpanByName('kms Decrypt')!);
    expect(a['rpc.service'], 'KMS');
    expect(a['rpc.method'], 'Decrypt');
    expect(a['aws.kms.key.id'], 'arn:aws:kms:us-east-1:123:key/abc');
    expect(a['aws.kms.algorithm'], 'SYMMETRIC_DEFAULT');
    expect(a['cloud.region'], 'us-east-1');
  });

  test('suppression skips spans', () async {
    await runWithoutAwsKmsInstrumentationAsync(() async {
      await tracedAwsKms<String>(
        operation: 'GenerateDataKey',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('kms '), isEmpty);
  });
}
