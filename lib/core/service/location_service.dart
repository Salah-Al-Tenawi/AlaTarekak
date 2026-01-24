// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationService {
//   static Future<bool> _checkPermissions() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return false;
//       }
//     }
    
//     if (permission == LocationPermission.deniedForever) {
//       await openAppSettings(); 
//       return false;
//     }
    
//     return true;
//   }

// static Future<Position?> getCurrentLocation() async {
//   try {
//     bool hasPermission = await _checkPermissions();
//     if (!hasPermission) return null;

//     Position position = await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.best, // أو أي مستوى دقة آخر تريده
//         distanceFilter: 0, // المسافة الدنيا للتحديث بالأمتار
//       ),
//     );
    
//     return position;
//   } catch (e) {
//     return null;
//   }
// }
// }