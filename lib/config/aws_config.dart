/// Centralized AWS configuration — values from `terraform output`
/// Update these values after each `terraform apply` if infrastructure changes.
class AwsConfig {
  AwsConfig._();

  // ── Region ─────────────────────────────────────
  static const String region = 'us-east-1';

  // ── API Gateway (HTTP) ─────────────────────────
  static const String httpApiBaseUrl =
      'https://0wn3u4avbk.execute-api.us-east-1.amazonaws.com/dev';

  // ── API Gateway (WebSocket) ────────────────────
  static const String websocketUrl =
      'wss://z3ik6ks0t8.execute-api.us-east-1.amazonaws.com/dev';

  // ── Cognito ────────────────────────────────────
  static const String cognitoIdentityPoolId =
      'us-east-1:d983cd58-2f6e-4265-9233-8efa1bc62a54';

  // ── S3 ─────────────────────────────────────────
  static const String mediaBucketName = 'mindconnect-dev-media-98b28d87';

  // ── ECS / ALB ──────────────────────────────────
  static const String albDnsName =
      'mindconnect-dev-alb-1593330677.us-east-1.elb.amazonaws.com';
}
