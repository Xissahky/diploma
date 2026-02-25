class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://diploma-kkqq.onrender.com', // for using deployed server
    // defaultValue: 'http://10.0.2.2:3000', // for test on localhost
  );
}
