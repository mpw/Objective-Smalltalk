
extension AppDelegate {
  -<void>showWorkspace:sender {
      workspace := MPWProgramTextView openInWindow:'Workspace'.
      workspace setCompiler: self compiler.
      workspace setDelegate: self.
  }

}
