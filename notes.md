# Async usb_modeswitch?


```
iex(17)> VintageNet.configure "ppp0", %{type: VintageNetLTE}

18:09:53.619 [error] PPP0!!!!!!!!!!!

18:09:53.650 [error] PPP0!!!!!!!!!!!
:ok
         
18:09:53.776 [debug] usb_modeswitch:Look for default devices ...
         
18:09:53.777 [debug] usb_modeswitch: Found devices in default mode (1)
         
18:09:53.777 [debug] usb_modeswitch:Access device 002 on bus 001
         
18:09:53.777 [debug] usb_modeswitch:Get the current device configuration ...
         
18:09:53.777 [debug] usb_modeswitch:Current configuration number is 1
         
18:09:53.777 [debug] usb_modeswitch:Use interface number 0
         
18:09:53.777 [debug] usb_modeswitch: with class 8
         
18:09:53.777 [debug] usb_modeswitch:Use endpoints 0x01 (out) and 0x81 (in)
         
18:09:53.778 [debug] usb_modeswitch:Using standard Huawei switching message
         
18:09:53.778 [debug] usb_modeswitch:Looking for active drivers ...
         
18:09:53.778 [debug] usb_modeswitch:Set up interface 0
         
18:09:53.778 [debug] usb_modeswitch:Use endpoint 0x01 for message sending ...
         
18:09:53.787 [debug] usb_modeswitch:Trying to send message 1 to endpoint 0x01 ...
         
18:09:53.787 [debug] usb_modeswitch: OK, message successfully sent
         
18:09:53.787 [debug] usb_modeswitch:Read the response to message 1 (CSW) ...
         
18:09:53.787 [debug] usb_modeswitch: Device seems to have vanished after reading. Good.
         
18:09:53.788 [debug] usb_modeswitch: Device is gone, skip any further commands
         
18:09:53.788 [debug] usb_modeswitch:-> Run lsusb to note any changes. Bye!
         
18:09:53.795 [info]  usb 1-1: USB disconnect, device number 2
         
18:09:53.816 [error] Starting PPPD!!!!!!!!!!!!!!!!!!!!
         
18:09:53.821 [error] /usr/sbin/pppd connect /usr/sbin/chat -v -f /tmp/vintage_net/twilio /dev/ttyUSB0 115200
         
18:09:54.279 [info]  usb 1-1: new high-speed USB device number 3 using musb-hdrc
         
18:09:54.461 [info]  usb 1-1: New USB device found, idVendor=12d1, idProduct=1506, bcdDevice= 1.02
         
18:09:54.461 [info]  usb 1-1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
         
18:09:54.462 [info]  usb 1-1: Product: HUAWEI_MOBILE
         
18:09:54.462 [info]  usb 1-1: Manufacturer: HUAWEI_MOBILE
         
18:09:54.598 [info]  usbcore: registered new interface driver option
         
18:09:54.599 [info]  usbserial: USB Serial support registered for GSM modem (1-port)
         
18:09:54.599 [info]  option 1-1:1.0: GSM modem (1-port) converter detected
         
18:09:54.617 [info]  usb 1-1: GSM modem (1-port) converter now attached to ttyUSB0
         
18:09:54.617 [info]  option 1-1:1.1: GSM modem (1-port) converter detected
         
18:09:54.618 [info]  usb 1-1: GSM modem (1-port) converter now attached to ttyUSB1
         
18:09:54.618 [info]  option 1-1:1.2: GSM modem (1-port) converter detected
         
18:09:54.618 [info]  usb 1-1: GSM modem (1-port) converter now attached to ttyUSB2
         
18:09:54.749 [info]  usbcore: registered new interface driver cdc_wdm
         
18:09:54.788 [info]  huawei_cdc_ncm 1-1:1.3: resetting NTB format to 16-bit
         
18:09:54.788 [info]  huawei_cdc_ncm 1-1:1.3: MAC-Address: 00:1e:10:1f:00:00
         
18:09:54.789 [info]  huawei_cdc_ncm 1-1:1.3: setting rx_max = 16384
         
18:09:54.789 [info]  huawei_cdc_ncm 1-1:1.3: NDP will be placed at end of frame for this device.
         
18:09:54.789 [info]  huawei_cdc_ncm 1-1:1.3: cdc-wdm0: USB WDM device
         
18:09:54.789 [info]  huawei_cdc_ncm 1-1:1.3 wwan0: register 'huawei_cdc_ncm' at usb-musb-hdrc.0-1, Huawei CDC NCM device, 00:1e:10:1f:00:00
         
18:09:54.789 [info]  usbcore: registered new interface driver huawei_cdc_ncm
```


It appears that `usb_modeswitch` finishes *after* we try to start `pppd`.

I don't believe VitageNet handles this yet.
