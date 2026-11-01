/// The two places an answer can sit on screen, and the two ways to lean.
enum AnswerSide {
  left,
  right;

  AnswerSide get opposite => this == left ? right : left;
}
