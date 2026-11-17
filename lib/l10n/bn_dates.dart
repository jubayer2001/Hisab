/// Month and weekday words as the app prints them in English, with their Bengali names.
const _months = {
  'January': 'জানুয়ারি',
  'February': 'ফেব্রুয়ারি',
  'March': 'মার্চ',
  'April': 'এপ্রিল',
  'May': 'মে',
  'June': 'জুন',
  'July': 'জুলাই',
  'August': 'আগস্ট',
  'September': 'সেপ্টেম্বর',
  'October': 'অক্টোবর',
  'November': 'নভেম্বর',
  'December': 'ডিসেম্বর',
  'Jan': 'জানুয়ারি',
  'Feb': 'ফেব্রুয়ারি',
  'Mar': 'মার্চ',
  'Apr': 'এপ্রিল',
  'Jun': 'জুন',
  'Jul': 'জুলাই',
  'Aug': 'আগস্ট',
  'Sep': 'সেপ্টেম্বর',
  'Oct': 'অক্টোবর',
  'Nov': 'নভেম্বর',
  'Dec': 'ডিসেম্বর',
};

const _weekdays = {
  'Sunday': 'রবিবার',
  'Monday': 'সোমবার',
  'Tuesday': 'মঙ্গলবার',
  'Wednesday': 'বুধবার',
  'Thursday': 'বৃহস্পতিবার',
  'Friday': 'শুক্রবার',
  'Saturday': 'শনিবার',
  'Sun': 'রবি',
  'Mon': 'সোম',
  'Tue': 'মঙ্গল',
  'Wed': 'বুধ',
  'Thu': 'বৃহস্পতি',
  'Fri': 'শুক্র',
  'Sat': 'শনি',
};

final RegExp _words = RegExp(
  r'\b(' + [..._months.keys, ..._weekdays.keys].join('|') + r')\b',
);
final RegExp _ampm = RegExp(r'\b(\d{1,2}:\d{2}) (AM|PM)\b');

/// Replaces English month and weekday words (from date formatting) and AM/PM with Bengali.
String swapDateWords(String s) {
  var out = s.replaceAllMapped(_ampm, (m) => '${m[2] == 'AM' ? 'সকাল' : 'বিকাল'} ${m[1]}');
  out = out.replaceAllMapped(_words, (m) => _months[m[1]] ?? _weekdays[m[1]] ?? m[0]!);
  return out;
}
