class ApiEndPoint {
  // ── اختيار الخادم ───────────────────────────────────────────────
  // بدّل [useLocalServer] فقط — لا تعدّل العناوين نفسها.
  //
  // المحلي: العنوان هو IPv4 لجهاز الكمبيوتر الذي يشغّل الباك إند على
  // نفس شبكة الواي فاي (اعرفه بـ ipconfig). لا تستخدم localhost ولا
  // 127.0.0.1 فهما يشيران إلى الهاتف نفسه لا إلى حاسوبك.
  // للمحاكي: 10.0.2.2 هو منفذ الوصول إلى localhost الحاسوب.
  //
  // ⚠️ المحلي يعمل في وضع التطوير فقط: HTTP العادي محجوب في نسخة
  // الإصدار، وهو مسموح في debug عبر usesCleartextTraffic في
  // android/app/src/debug/AndroidManifest.xml.
  static const bool useLocalServer = false;

  static const _localServer = "http://192.168.0.104:8000";
  static const _productionServer = "https://api.onwayride.me";

  static const serverRoot = useLocalServer ? _localServer : _productionServer;
  static const baserUrl = "$serverRoot/api";
  static const broadcastAuth = "$serverRoot/broadcasting/auth";

  static const mapsOpenRouteServices =
      "https://api.openrouteservice.org/v2/directions/driving-car/geojson";
  static const mapsGraphHopper = "https://graphhopper.com/api/1/route";

  // auth

  static const login = "$baserUrl/auth/login";
  static const singin = "$baserUrl/auth/signup";
  static const logout = "$baserUrl/logout";
  static const forgetPassword = "$baserUrl/auth/password/forgot";
  static const verfiyOtpforgetPassword = "$baserUrl/auth/password/verify-otp";
  static const resetPassword = "$baserUrl/auth/password/reset";
  static const profile = "$baserUrl/profile";

  static const verifypassenger = "$profile/verify/passenger";
  static const verifydriver = "$profile/verify/driver";
  static const rateUser = "$profile/rate";
  static const emailVerfivaction = "$baserUrl/email-verification/verify";
  static const resendOtp = "$baserUrl/email-verification/resend";
  
  // token 
  static const refreshToken = "$baserUrl/auth/refresh";

//  trips endpoint
  static const rides = "$baserUrl/rides";
  static const createRide = "$rides/create-with-route";
  static const search = "$rides/search";

  // epy — المحفظة تُنشأ برقم الهاتف مباشرة بلا رمز تحقق
  static const getbalance = "$baserUrl/wallet/balance";
  static const createWalletDirect = "$baserUrl/wallet/create-direct";
  // كشف الحساب — وهو المصدر الوحيد الذي يكشف cash_ride_debt
  static const walletTransactions = "$baserUrl/wallet/transactions";

  // bookings — حجوزاتي كراكب + إجراءات الحجز (cancel / cancel-seats / passenger-confirm / accept / reject)
  static const bookings = "$baserUrl/bookings";
  static const bookingme = bookings;

// chat

   static const chat = "$baserUrl/chat";
   static const conversation = "$chat/conversations";

 static const message = "$chat/conversations";
 static const deletmessage = "$chat/messages";

  // notifications (§10)
  static const notifications = "$baserUrl/notifications";
  static const notificationsUnreadCount = "$notifications/unread-count";
  static const notificationsReadAll = "$notifications/read-all";
  static const notificationsBulkAction = "$notifications/bulk-action";
  static const notificationsCategories = "$notifications/categories";

  // FCM push tokens
  static const pushRegister = "$baserUrl/push/register";
  static const pushRemove = "$baserUrl/push/remove";

  // score (§5)
  static const score = "$baserUrl/score";
  static const scoreHistory = "$score/history";

  // support & complaints
  static const complaints = "$baserUrl/complaints";
  static const contact = "$baserUrl/contact";



}

class ApiKey {
  // Authorization
  static const authorization = "Authorization";
  static const data = "data";
  static const success = "success";
  static const message = "message";
  static const resetToken = "reset_token";

  static const error = "error";
  static const token = "access_token";
  static const contentType = "Content-Type";
  // token 
  static const refreshToken="refresh_token";

  // User Info
  static const userId = "user_id";
  static const id = "id";
  static const user = "user";
  static const fullName = "full_name";
  static const firstName = "first_name";
  static const lastName = "last_name";
  static const address = "address";
  static const email = "email";
  static const password = "password";
  static const passwordConfirm = "password_confirmation";
  static const gender = "gender";
  static const profilePhoto = "profile_photo";
  static const description = "description";
  static const verificationStatus = "verification_status";
  static const numberOfRides = "number_of_rides";
  static const drivingLicensePic = "driving_license_pic";
  static const rating = "rating";
  static const totalRatings = "total_ratings";
  static const averageRating = "average_rating";
  static const phoneNumber = "phone_number";
  static const otpCode = "otp_code";


  // Car Info
  static const typeOfCar = "type_of_car";
  static const colorOfCar = "color_of_car";
  static const numberOfSeats = "number_of_seats";
  static const carPic = "car_pic";
  static const radio = "radio";
  static const smoking = "smoking";

  // Documents
  static const documents = "documents";
  static const faceIdPic = "face_id_pic";
  static const backIdPic = "back_id_pic";
  static const licensePic = "driving_license_pic";
  static const mechanicCardPic = "mechanic_card_pic";

  // Comments

  static const name = "name";
  static const comments = "comments";
  static const comment = "comment";
  static const commenter = "commenter";
  static const createdAt = "created_at"; 
  

  // rides crate
  static const pickupAddress = "pickup_address";
  static const destinationAddress = "destination_address";
  static const departureTime = "departure_time";
  static const availableSeats = "available_seats";
  static const seats = "seats";
  static const pricePerSeat = "price_per_seat";
  static const pickuplat = "pickup_lat";
  static const pickuplng = "pickup_lng";
  static const destinationlat = "destination_lat";
  static const destinationlng = "destination_lng";
  static const notes = "notes";
  static const routeIndex = "route_index";
  static const paymentmethod = "payment_method";
  static const bookingType = "booking_type";
  static const communicationNumber = "communication_number";

  // maps
  static const coordinates = "coordinates";
  static const alternativeRoutes = "alternative_routes";
  static const targetCount = "target_count";
  static const shareFactor = "share_factor";
  static const features = "features";

// search trip
  static const sourceAddress = "source_address";
  static const departureDate = "departure_date";
  static const seatsRequired = "seats_required";
  static const sourcelat = "source_lat";
  static const sourcelng = "source_lng";
  static const destlat = "dest_lat";
  static const destlng = "dest_lng"; 
  // caht 
  static const  conversationid ="conversation_id";
   static const  type ="type";
    static const  title ="title";
     static const  otherparticipant ="other_participant";
      static const  lastmessage ="last_message";
       static const  updatedat ="updated_at";
        static const  content ="content";
         static const  metadata ="metadata";
          static const  isedited ="is_edited";
        static const  avatar ="avatar";
          static const  caption ="caption";
            static const  image ="image";
         static const  createdat ="created_at";
            static const  sender ="sender";
             static const  sendername ="sender_name";
}
