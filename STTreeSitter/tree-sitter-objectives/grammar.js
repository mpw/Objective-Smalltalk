/**
 * @file Parser for Objective-S
 * @author Marcel Weiher <marcel@metaobject.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "objectives",

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => "hello"
  }
});
