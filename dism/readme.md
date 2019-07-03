(Windows Surface RT (ARM))<br>
### Method to image the logical volume(s) of the device by using DISM ###

* First you need to have an access to the system, in other words you have to log into the system. If you don't have the user password, you must find a way to find it.
* When you are logged in the system, you need to generate the bitlocker-key. These devices are automatically protected with bitlocker when you register the system the first time with your Windows live account.
* You'll need the key to unencrypt your image file.

* Then, when the OS is booted, hold on the left shift-key and click on reboot
* You should see the advanced options menu
* Click on Troubleshoot -- > Advanced Options -- > Command prompt
* If everything's worked fine a command prompt should appear. That's it, now you can use the command dism to make a volume disk image.
* If needed you can use diskpart to assign a letter to the hidden volumes/other partitions.
* Use the command Diskpart -- > list volume -- > select volume X -- > assign letter=X
* Ok now that every volume is assigned, now you can use the command dism

**dism /capture-image /imagefile:X:\"yourimagefile".WIM /capturedir:c:\ /name:winrt**

/imagefile : choose the path and the name of the file you want to create
/capturedir : choose the volume you want to copy
/name : choose a label

* Now that the primary volume is copied, you can append the hidden volumes to your image.
* Use the command

dism /append-image /imagefile:X:"yourimagefile" /capturedir:d:\ /name:system

* You have now a .wim file !
* Copy your Wim file on your work computer.
* Open a command prompt and use the dism command again.
* You need to "mount" your file to extract the files on your computer.
* First type

**dism /get-wiminfo /wimfile:X:"path to your wim file"**

* Normally you should see the different partitions that you have imaged, each one corresponding to an index.
* Type now the following command

**"dism /mount-wim /wimfile:X:"path to your wim file" /index:X /mountdir:X:\path to extract the files"**

/index: choose the number of the index (volume) you want to extract
/mountdir: choose the directory where to extract the files

* Once finished to unmount type the following command 

**dism /unmount-wim /mountdir:X:"path to your wim file" /discard  **

[source](https://www.forensicfocus.com/Forums/viewtopic/p=6599093/#6599093)
