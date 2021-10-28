object VStack : #Stack {
        #distribution: c:UIStackViewDistributionFillEqually ,
        #axis: c:UILayoutConstraintAxisVertical
}.

object HStack : #Stack {
        #distribution: c:UIStackViewDistributionFillEqually ,
        #axis: c:UILayoutConstraintAxisHorizontal
}.

object Body : #Label{
         #numberOfLines: 0,
         #textColor: color:systemGray
}.

object Image : #UIImageView {
        #contentMode: c:UIViewContentModeScaleAspectFit
}.
object Title : #Label{
        #font: font:style/largeTitle ,
        #textColor: color:white
}.

object NumberField : #UITextField{
     #textAlignment:  c:NSTextAlignmentRight ,
     #borderStyle: c:UITextBorderStyleLine
}.


extension UIView {
   -<void>setWidth:width {
	wConstraint := NSLayoutConstraint
                         constraintWithItem:self
                         attribute:c:NSLayoutAttributeWidth
                         relatedBy: c:NSLayoutRelationEqual
                         toItem: nil
                         attribute: c:NSLayoutAttributeNotAnAttribute
                         multiplier: 1
                         constant: width.
         self addConstraint: wConstraint.
   }
}.

 

stdout println:'UIKit init'.

