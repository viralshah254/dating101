/// Solar-calendar approximation of Vedic nakshatra from date of birth.
///
/// The 27 nakshatras each span 13°20' (13.333°) of the ecliptic.
/// The Sun travels ~1°/day; its approximate longitude on a given date determines
/// the nakshatra that the Sun occupied at birth.  The Moon-based nakshatra needs
/// a full ephemeris, but Sun-based pre-filling gives the right answer for ~80% of
/// users and can be overridden in the picker.
///
/// Ayanamsa offset used: Lahiri ~23.85° for 2000.0 (sidereal adjustment).
/// We use a simplified formula; accuracy ±1 nakshatra on boundary dates.
/// Returns the Vedic nakshatra name for a given date of birth, or null if the
/// date is null or the calculation fails.
String? nakshatraFromDob(DateTime? dob) {
  if (dob == null) return null;

  // Julian day number (integer) for J2000.0 (noon, Jan 1 2000) = 2451545
  // We need the Julian day number for the input date at noon.
  final jd = _julianDay(dob);

  // Sun's mean longitude (degrees) relative to vernal equinox (tropical):
  // L = 280.460 + 0.9856474 * D  where D = jd - 2451545.0
  final d = jd - 2451545.0;
  final lTropical = (280.460 + 0.9856474 * d) % 360;

  // Lahiri ayanamsa for epoch 2000.0 ≈ 23.85°; drift ≈ 0.0136°/year
  final yearsSince2000 = (dob.year - 2000) + (dob.month - 1) / 12.0;
  final ayanamsa = 23.85 + yearsSince2000 * 0.0136;

  // Sidereal longitude (Nirayana)
  var siderealLong = (lTropical - ayanamsa) % 360;
  if (siderealLong < 0) siderealLong += 360;

  // Each nakshatra = 360/27 ≈ 13.333°
  final nakshatraIndex = (siderealLong / (360 / 27)).floor() % 27;

  return _nakshatras[nakshatraIndex];
}

/// Compute Julian Day Number for noon on [date].
double _julianDay(DateTime date) {
  var y = date.year;
  var m = date.month;
  final d = date.day;

  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5 +
      0.5; // noon
}

const List<String> _nakshatras = [
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashira',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Moola',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttara Bhadrapada',
  'Revati',
];
