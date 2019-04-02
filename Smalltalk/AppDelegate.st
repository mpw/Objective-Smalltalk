
extension AppDelegate {
  -<void>showWorkspace:sender {
      scrollView := NSScrollView alloc initWithFrame: (0@0 extent: 500@400) | autorelease.
      scrollView setAutoresizingMask: 18.
      scrollView setHasVerticalScroller: 1.
      workspace := MPWProgramTextView alloc initWithFrame: (0@0 extent: 500@400).
      scrollView setDocumentView:workspace.
      scrollView openInWindow:'Workspace'.
      workspace setCompiler: self compiler.
      workspace setDelegate: self.
      stdout println:'did set up workspace'.
  }
}
