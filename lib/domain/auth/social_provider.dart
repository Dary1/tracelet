enum AuthMode {
  guest,
  social,
}

enum SocialProvider {
  google('Google'),
  apple('SignInWithApple');

  const SocialProvider(this.cognitoIdpName);

  final String cognitoIdpName;
}
