enum UserSessionStatus {
  success,
  fail,
  passwordExchanged,
  passwordExchangedFail,
  userLocked
}

extension UserSessionStatusExtension on UserSessionStatus {
  String get message {
    switch (this) {
      case UserSessionStatus.success:
        return "로그인 성공";
      case UserSessionStatus.fail:
        return "아이디 또는 비밀번호를 확인하세요";
      case UserSessionStatus.passwordExchanged:
        return "비밀번호가 변경되었습니다. 다시 로그인하세요";
      case UserSessionStatus.passwordExchangedFail:
        return "";
      case UserSessionStatus.userLocked:
        return "계정이 잠겼습니다. 관리자에게 문의하세요";
    }
  }
}
