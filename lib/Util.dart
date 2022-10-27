extension DurationDivision on Duration {
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;
}
