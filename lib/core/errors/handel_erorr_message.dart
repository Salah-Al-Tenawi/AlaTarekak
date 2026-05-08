
class HandelErorrMessage {
  static String login(String message) {
    switch (message) {
      case "Invalid credentials":
        return "كلمة المرور غير صحيحة";
      default:
        return "حدث خطأ غير متوقع";
    }
  }

  static String singin(String message) {
    return "";
  }

  static String forgetPassword(String message) {
    return "";
  }

  static String resetPassword(String message) {
    return "";
  }

  static String initialWallet(String message) {
    return "";
  }

  static String createWallet(String message) {
    return "";
  }

  static String checkbalance(String message) {
    return "";
  }

  static String showProfile(String message) {
    return "";
  }

  static String updateProfile(String message) {
    return "";
  }

  static String commet(String message) {
    return "";
  }

  static String verfiyPassanger(String message) {
    return "";
  }

  static String verfiyDriver(String message) {
    return "";
  }

  static String rateUser(String message) {
    return "";
  }

  static String showAllride(String message) {
    return "";
  }

  static String showOneRide(String message) {
    return "";
  }

  static String bookAset(String message) {
    switch (message) {
      case "You have already booked this ride":
        return "لقد قمت بالحجز فعلا";
      default:
        return "حدث خطأ غير متوقع";
    }
  }

  static String search(String message) {
    return "";
  }

  static String createWithRoute(String message) {
    String lowerCaseMessage = message.toLowerCase();

    if (lowerCaseMessage.contains("missing required verification documents")) {
      return "يجب عليك توثيق حسابك لضمان الأمان";
    } else if (lowerCaseMessage
        .contains("you must be verified as a driver to create rides")) {
      return "يجب عليك توثيق حسابك لضمان الأمان";
    } else if (lowerCaseMessage.contains("insufficient wallet balance")) {
      return "لا يوجد رصيد كافي في المحفظة";
    } else if (lowerCaseMessage.contains("departure_time")) {
      return "لا يمكنك انشاء رحلة بتوقيت قريب اقل من 5 دقائق";
    } else {
      return "حدث خطأ غير متوقع";
    }
  }


  static String finishRide(String message) {
    switch (message) {
      case "No confirmed bookings found for this ride":
        return "لا يوجد حجوزات في هذه الرحلة يمكنك الغائها بدلا من ذلك";
      default:
        return "حدث خطأ غير متوقع";
    }
  }

  static String bookingMe(String message) {
    switch (message) {
      case "You must be verified as a passenger to view bookings":
        return "لم يتم توثيق الحساب ";


      case " Ride is not in confirmation state":

        return "لم يتم توثيق انهاء الرحلة من قبل السائق بعد  ";


      default:
        return "حدث خطأ غير متوقع";
    }
  }

  static String driverConfirm(String message) {
    return "";
  }

  static String passangerConfirm(String message) {
    return "";
  }

  static String acceptPassanger(String message) {
    return "";
  }

  static String rejectPassanger(String message) {
    return "";
  }
}
