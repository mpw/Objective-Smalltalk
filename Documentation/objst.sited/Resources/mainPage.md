<p>

#### Objective-Smalltalk

Elegantly compose modern software by going beyond algorithms and data structures.

#### Hello World!

<table>
<tr>
<td>standard I/O</td> <td>GUI</td> <td>Web server </td>
</tr>
<tr  valign="top" font-weight="bold">
<td> stdout println: 'hello world'.
</td> <td>#TextField{ value:'Hello World' } → stdout  </td> <td>
#HTTPServer{ port:8080 } → #DictStore{ hello: 'world' }   . 
</td>
</tr>

<tr height=100  valign="top">
<td width="30%" > Standard hello world that prints our greeting to the console.</td> <td width="30%"> A text field connected to the console.  It is seeded with our greeting, but we can enter any other text to print to the console.  </td> <td width="30%">
A web server connected to a dictionary that contains the string 'world' at the key 'hello'.  The web-server will serve that string 'world' at the path 'hello'.
 
</td>
</tr>
</table>




#### Beyond Hello World




More [here](About).

#### Try it out