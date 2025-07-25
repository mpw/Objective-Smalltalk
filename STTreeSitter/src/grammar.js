module.exports = grammar({
  name: 'sample',

  rules: {
    source_file: $ => repeat($.statement),

    statement: $ => seq($.identifier, '=', $.number, ';'),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
    number: $ => /\d+/,
  }
});