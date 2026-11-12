enum Sex { female, male }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725);

  const ActivityLevel(this.factor);
  final double factor;
}

enum WeightAim {
  lose(-500),
  maintain(0),
  gain(300);

  const WeightAim(this.offset);
  final int offset;
}

/// Daily energy need in kcal from the Mifflin-St Jeor equation times an
/// activity factor, shifted by the aim and rounded to 50 kcal. Never below
/// 1200 kcal - lower targets belong under medical supervision.
int calorieGoal({
  required Sex sex,
  required int age,
  required double heightCm,
  required double weightKg,
  required ActivityLevel activity,
  required WeightAim aim,
}) {
  final bmr =
      10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161);
  final need = bmr * activity.factor + aim.offset;
  final rounded = (need / 50).round() * 50;
  return rounded < 1200 ? 1200 : rounded;
}
