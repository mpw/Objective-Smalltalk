package tree_sitter_objectives_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_objectives "github.com/tree-sitter/tree-sitter-objectives/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_objectives.Language())
	if language == nil {
		t.Errorf("Error loading Objective-S grammar")
	}
}
