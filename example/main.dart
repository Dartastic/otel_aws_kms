// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_aws_kms/otel_aws_kms.dart';

/// Traces AWS KMS calls with OpenTelemetry.
///
/// `otel_aws_kms` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each AWS KMS call in
/// [tracedAwsKms]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'aws-kms-example');

  // Wraps an AWS KMS API call (Encrypt, Decrypt, GenerateDataKey, Sign, Verify, ReEncrypt) in a CLIENT span.
  final awsKmsId = await tracedAwsKms<String>(
    operation: 'create',
    keyId: 'key_8f3a2c',
    algorithm: 'example',
    region: 'us-east-1',
    invoke: () async {
      // Make the AWS KMS call here, then report what it returned.
      return 'aws_kms_8f3a2c';
    },
  );
  OTelLog.info('tracedAwsKms create returned $awsKmsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAwsKmsInstrumentationAsync.
  await runWithoutAwsKmsInstrumentationAsync(
    () => tracedAwsKms<String>(
      operation: 'create',
      keyId: 'key_8f3a2c',
      algorithm: 'example',
      region: 'us-east-1',
      invoke: () async {
        return 'aws_kms_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
