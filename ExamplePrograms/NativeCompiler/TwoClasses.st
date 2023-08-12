class Hello
{
   -main:args
   {
        var greeter.
	greeter := class:Greeter new.
        self Stdout print: 'greeter: '. self Stdout println:greeter.
        greeter greet:'Hello World via greeter' on:self Stdout.
        0.
   }
}
class Greeter 
{
   -greet:msg on:stdout {
	stdout println:msg.
   }
   -main:args {
       self Stdout println:'greeter''s main called'.
       0.
   }
}
