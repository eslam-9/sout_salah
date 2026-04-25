import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  const NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // In connectivity_plus, result is a list in newer versions, but wait, let's check the version installed.
    // connectivity_plus 6.1.5 uses `List<ConnectivityResult>` for checkConnectivity in 6.0.0+? Wait.
    // connectivity_plus ^6.0.0 uses List<ConnectivityResult>.
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  }
}
