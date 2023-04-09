left := c:NSTextAlignmentLeft.

object Label : #STTextField{
    #bordered: false,
    #selectable: false,
    #drawsBackground: false,
    #alignment: c:NSTextAlignmentLeft ,
    #textColor: color:systemGray

}.

object Body : #STTextField{
    #bordered: false,
    #selectable: false,
    #drawsBackground: false,
    #alignment: c:NSTextAlignmentLeft ,
    #textColor: color:systemGray
}.

object Title : #STTextField{
    #bordered: false,
    #selectable: false,
    #drawsBackground: false,
    #alignment: c:NSTextAlignmentLeft ,
    #textColor: color:white
}.

object TextField : #STTextField{
     #continuous: true
}.

object NumberField : #STTextField{
     #continuous: true,
     #alignment: c:NSTextAlignmentRight
}.

object VStack : #NSStackView {
        #alignment:     c:NSLayoutAttributeLeft ,
        #distribution:  c:NSStackViewDistributionFillEqually ,
        #orientation:   c:NSUserInterfaceLayoutOrientationVertical
}.

object HStack : #NSStackView {
        #distribution:  c:NSStackViewDistributionFillEqually ,
        #orientation:   c:NSUserInterfaceLayoutOrientationHorizontal
}.

