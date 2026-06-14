/// Configuração central de acesso à API (backend FastAPI).
///
/// A URL base fica em UM único lugar. Troque conforme o alvo de execução:
/// - Desktop (Windows/macOS/Linux) e iOS Simulator: http://127.0.0.1:8000
/// - Emulador Android:                                http://10.0.2.2:8000
/// - Dispositivo físico:                              http://<IP-da-LAN>:8000
///
/// Em vez de editar o código, dá pra sobrescrever na linha de comando:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// (útil para CI e para cada dev apontar pro próprio backend).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
