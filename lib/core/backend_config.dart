/// Dev AWS endpoints from `terraform output` (ap-northeast-1).

abstract final class BackendConfig {

  static const awsRegion = 'ap-northeast-1';



  static const httpApiUrl =

      'https://7u36u4btpd.execute-api.ap-northeast-1.amazonaws.com/dev';



  static const websocketApiUrl =

      'wss://26cgcyz3h0.execute-api.ap-northeast-1.amazonaws.com/dev';



  static const cognitoUserPoolId = 'ap-northeast-1_teVdYaqBM';



  static const cognitoUserPoolClientId = '7ceu7ck4452oe0v3tvnfa8qgdt';



  static const cognitoHostedUiDomain =

      'tracelet-dev-auth.auth.ap-northeast-1.amazoncognito.com';



  static const oauthRedirectUri = 'tracelet://auth/callback';



  static const oauthCallbackScheme = 'tracelet';



  /// Set true after Google IdP is configured in Cognito (terraform).

  static const googleSignInEnabled = true;



  /// Set true after Apple IdP is configured in Cognito (terraform).

  static const appleSignInEnabled = false;

}

