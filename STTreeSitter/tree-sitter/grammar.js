module.exports = grammar({
  name: 'objectives',

  rules: {
    source_file: $ => repeat($.statement),

    statement: $ => seq($.identifier1, '=', $.number, ';'),

    identifier1: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
    number: $ => /\d+/,
  }
});
