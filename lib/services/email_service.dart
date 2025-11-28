import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config.dart';

class EmailService {
  // إرسال OTP
  static Future<void> sendOtp(String toEmail, String otp) async {
    final subject = 'MindQuest OTP Verification';
    final body = 'Your OTP code is: $otp\n\nDo not share it with anyone.';

    final ok = await _sendEmailRaw(toEmail, subject, body);

    if (!ok) {
      // فشل الإرسال — fallback للتطوير: طباعة OTP في الكونسل
      print('*** OTP fallback (email failed) for $toEmail => $otp ***');
    }
  }

  // إرسال طلب إعادة تعيين كلمة المرور
  static Future<void> sendPasswordResetRequest(String toEmail) async {
    final subject = 'MindQuest Password Reset';
    final body =
        'We received a request to reset your password.\n'
        'If this was you, please follow the instructions in the app.\n'
        'If not, ignore this message.';

    final ok = await _sendEmailRaw(toEmail, subject, body);

    if (!ok) {
      print('*** Password reset email FAILED for $toEmail ***');
    }
  }

  // دالة مساعدة لإرسال البريد مع طباعة الأخطاء
  static Future<bool> _sendEmailRaw(String toEmail, String subject, String body) async {
    // إذا لم يتم تكوين SMTP، نرجع false
    if (SMTP_USERNAME.isEmpty || SMTP_PASSWORD.isEmpty) {
      print('*** SMTP not configured. Email not sent to $toEmail ***');
      return false;
    }

    final smtpServer = SmtpServer(
      SMTP_HOST,
      port: SMTP_PORT,
      username: SMTP_USERNAME,
      password: SMTP_PASSWORD,
      ssl: SMTP_PORT == 465,
      ignoreBadCertificate: true,
    );

    final message = Message()
      ..from = Address(FROM_EMAIL, FROM_NAME)
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('MailerException: ${e.toString()}');
      for (var p in e.problems) {
        print(' - problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unexpected email error: $e');
      return false;
    }
  }
}



