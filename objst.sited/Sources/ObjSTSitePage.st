class ObjSTSitePage : MetaobjectPage
{
-cssString {
 '
body {
font-size : 12pt; 
font-family : Verdana,Arial, Helvetica, sans-serif; 
font-weight : light;  
width : 85%;
}

pre  {
  background-color: #f5faff;
  border-style:solid;
  border-width:1px;
  border-color: #a0a0a0;
  border-radius: 5px;
  padding: 12px; 
  margin-top:20px;
  margin-bottom:20px;
  margin-right:5px;
  margin-left: 2em;
  line-height: 1.4;
}

code {
font-size : 11pt; 
font-family : Courier, fixed-width; 
font-weight : normal;  
width : 85%;
}

h3 {
  font-family: Eurostile, "Eurostile W01 Regular", Helvetica;
  font-weight: normal;
font-size : 13pt; 
}

h2 {
  font-family: Eurostile, "Eurostile W01 Regular", Helvetica;
  font-weight: normal;
font-size : 15pt; 
}

h1 {
  font-family: Eurostile, "Eurostile W01 Regular", Helvetica;
  font-weight: normal;
font-size : 24pt; 
}

a { font-size: small; text-decoration: none; color: #004c93}
a:visited { color: #800000 }
a:hover { color: #ff0000}
p { margin-right: 100px  }
td { font-size: small   }
li {  font-size: small }
img.icon { float: left; padding-right: 4px }
img.oopsla { float: right; border: none }
[name=mainContent] {
   margin-left: 22px;
}

'.
}
-pageCopyright {
  'Copyright (c) 2012-2020 Marcel Weiher (st)'.
}
-<void>renderHeaderRow:aRenderer {

 aRenderer writeObject:'<td><img width=50 height=50 src="/objst.png" style="webkit-border-radius:8px; color:#ffffff; border:1px solid #000"></td>' asData.


 aRenderer writeObject:'<td style=" text-align: right; vertical-align: bottom; -webkit-border-radius:8px; color:#ffffff; border:1px solid #000; halign:right; background-color: #7197E0">objective.st</td>' asData.


}
-<void>renderStyleOn:aRenderer {
 css :=  self cssString.
 aRenderer writeObject:( '<style  type="text/css">' , self cssString,  '</style>' ) asData.
}
-siteName {
 'Objective-S'.

}
-styleName {
 'meta'.

}

}.
