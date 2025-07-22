#!env st
# port is specified via defaults, so: -port <number>
#-helloHttp
framework:ObjectiveHttpd load.
scheme hello  {
   /hello { get { 'World!' } }
}
