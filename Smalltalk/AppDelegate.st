
extension STDocument {

  -compiler {
     NSApplication sharedApplication delegate compiler.
  }

  -<void>showWorkspace:sender {
      scrollView := NSScrollView alloc initWithFrame: (0@0 extent: 500@400) | autorelease.
      scrollView setAutoresizingMask: 18.
      scrollView setHasVerticalScroller: 1.
      workspace := MPWProgramTextView alloc initWithFrame: (0@0 extent: 500@400).
      scrollView setDocumentView:workspace.
      window := scrollView openInWindow:'Workspace'.
      window setDelegate:self.
      workspace setCompiler: self compiler.
      workspace setDelegate: self.
      self workspaces addObject:workspace.
      stdout println:'did set up workspace'.
  }


}
