SKIPUNZIP=0

ui_print "****************************************"
ui_print "*      Pixel to TV Box Transformer     *"
ui_print "*             by preetstyle            *"
ui_print "****************************************"
ui_print "- Installing boot scripts..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm_recursive $MODPATH/kiosk 0 0 0755 0644
ui_print "- Installation complete! Reboot to activate TV Box Mode."
