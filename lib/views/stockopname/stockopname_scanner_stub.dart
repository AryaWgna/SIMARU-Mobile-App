import 'package:flutter/foundation.dart';

// Gunakan implementasi yang sesuai berdasarkan platform
export 'stockopname_mobile_scanner.dart'
    if (dart.library.html) 'stockopname_web_scanner.dart'; 