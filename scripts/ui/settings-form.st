#!env stui
#-settings

nameField ← #TextField{ stringValue: 'Taylor', frame: (200@24) }.
emailField ← #TextField{ stringValue: 'taylor@example.com', frame: (200@24) }.

notificationsSwitch ← #NSSwitch{ state: 1 }.
soundsSwitch ← #NSSwitch{ state: 1 }.

frequencyPopUp ← #PopUp{ items: [ 'Daily', 'Weekly', 'Monthly' ] }.
frequencyPopUp selectItemAtIndex: 1.

appearanceControl ← #NSSegmentedControl{ segments: [ 'System', 'Light', 'Dark' ] }.

resetButton ← #Button{ title: 'Reset All Settings' }.

grid ← #Grid{ frame: (20@20 extent: 400@340), #rows: [
   [ #Label{ text: 'Name' },          nameField ],
   [ #Label{ text: 'Email' },         emailField ],
   [ #Label{ text: 'Notifications' }, notificationsSwitch ],
   [ #Label{ text: 'Sounds' },        soundsSwitch ],
   [ #Label{ text: 'Summary' },       frequencyPopUp ],
   [ #Label{ text: 'Color scheme' },  appearanceControl ],
   [ #Label{ text: 'Text size' },     #Label{ text: 'Default' } ],
   [ resetButton ],
] }.

window ← #NSWindow{ frame: (300@300 extent: 440@420), title: 'Settings', views: [ grid ] }.
app runFromCLI: window.
