class Hello
{
   -main:args
   {
        var dict.
        var store.
        dict := class:NSMutableDictionary dictionary.
        self Stdout println:dict.
        self Stdout println:'Hello World'.
        self Stdout println: dict class.
        dict at:'hello' put:'World!'.
        self Stdout println:dict.
        store := class:MPWDictStore storeWithDictionary:dict.
        self Stdout println:store.
        store serveOn:9001.
        self Stdout println:'started serving'.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
