/// Expected shape of the user's answer for a field (drives prompts / hints).
enum QuestionFieldType {
  /// Free-form text (names, descriptions, etc.)
  text,

  /// Numeric values (age, counts, years of experience, etc.)
  numeric,

  /// Email addresses — enforces one `@` and a domain with a dot (e.g. `name@example.com`).
  email,

  /// Phone numbers — requires at least 8 digits; `+`, spaces, `-`, and `()` are allowed.
  phone,

  /// Dates or date-like strings (e.g. "18-1-1998")
  date,

  /// URLs (LinkedIn, websites, etc.)
  url,
}
