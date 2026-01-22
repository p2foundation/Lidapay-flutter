import '../../data/models/api_models.dart';

/// Prymo network code mapping for Ghana operator IDs.
class GhanaNetworkCodes {
  static const int defaultNetworkCode = 0; // Auto-detect

  // Network code constants
  static const int unknown = 0;      // Auto detect network
  static const int airtelTigo = 1;   // AirtelTigo
  static const int expresso = 2;     // EXPRESSO
  static const int glo = 3;          // GLO
  static const int mtn = 4;          // MTN
  static const int tigo = 5;         // TiGO
  static const int telecel = 6;      // Telecel
  static const int busy = 8;         // Busy
  static const int surfline = 9;     // Surfline
  static const int mtnYellow = 13;   // MTN Yellow

  // Mapping from operator IDs to network codes
  static const Map<int, int> _operatorIdToNetworkCode = {
    // MTN Ghana
    150: mtn,          // MTN Ghana
    643: mtn,           // MTN Ghana Data
    
    // AirtelTigo Ghana
    151: airtelTigo,    // AirtelTigo Ghana
    642: airtelTigo,    // AirtelTigo Ghana Data
    
    // Telecel Ghana (formerly Vodafone)
    152: telecel,       // Telecel Ghana
    770: telecel,       // Telecel Ghana Data
    
    // Glo Ghana
    153: glo,           // Glo Ghana
    644: glo,           // Glo Ghana Data
    
    // Expresso
    154: expresso,      // Expresso Ghana
    645: expresso,      // Expresso Ghana Data
    
    // Busy
    155: busy,          // Busy Ghana
    646: busy,          // Busy Ghana Data
    
    // Surfline
    156: surfline,      // Surfline Ghana
    647: surfline,      // Surfline Ghana Data
    
    // TiGO (separate from AirtelTigo)
    157: tigo,          // TiGO Ghana
    648: tigo,          // TiGO Ghana Data
    
    // MTN Yellow
    158: mtnYellow,     // MTN Yellow Ghana
    649: mtnYellow,     // MTN Yellow Ghana Data
  };

  // Get network code from operator ID
  static int fromOperatorId(int operatorId, {int fallback = defaultNetworkCode}) {
    return _operatorIdToNetworkCode[operatorId] ?? fallback;
  }

  // Get network code from auto-detection result
  static int fromAutodetectResult(AutodetectData autodetectData) {
    // Use the operator ID from auto-detection to get the network code
    return fromOperatorId(autodetectData.operatorId);
  }

  // Get network name from code
  static String getNetworkName(int networkCode) {
    switch (networkCode) {
      case unknown:
        return 'Auto Detect';
      case airtelTigo:
        return 'AirtelTigo';
      case expresso:
        return 'EXPRESSO';
      case glo:
        return 'GLO';
      case mtn:
        return 'MTN';
      case tigo:
        return 'TiGO';
      case telecel:
        return 'Telecel';
      case busy:
        return 'Busy';
      case surfline:
        return 'Surfline';
      case mtnYellow:
        return 'MTN Yellow';
      default:
        return 'Unknown';
    }
  }
}
