class Hello
{
   -main:args
   {
        var dict.
        var store.
        store := MPWDictStore store.
        scheme:db := store.
        db:hello := 'World'.
        store serveOn:9001.
        self Stdout println: scheme:db.
        self Stdout println:'started serving'.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
