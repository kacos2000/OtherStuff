## How to get a full physical dump from Minix Neo X7 ##
(The RK3188 features a quad-core ARM Cortex-A9) and Android 4.2 – 4.4)


The utility [RKdumper](https://forum.xda-developers.com/general/rooting-roms/tool-rkdumper-utility-backup-firmware-t2915363) 
(see [.log](https://github.com/kacos2000/Other/blob/master/Minix/rkdumper.log) with output from a test) Dump of only the system and user partitions).<br> 

Use the driver set from Rockchip [Source #1](https://github.com/chirimen-oh/CHIRIMEN-tools) or [Source #2](https://androidmtk.com/download-rockchip-driver-assistant), 
to get a dump of all the partitions.

For RKdumper to work, you need a Windows cmd terminal with admin privileges, 
and you also need to put the RockChip device in recovery(firmware flash) mode 
(press the recessed recover button and keep pressing while powering device on until seen by the PC). 

No need to connect device to display. Just the mini-usb cable attached to PC and power.

07-Jun-17  06:13 PM        67,108,864 backup.img<br>
07-Jun-17  06:12 PM        12,402,688 boot.img<br>
07-Jun-17  06:13 PM       134,217,728 cache.img<br>
07-Jun-17  06:12 PM        12,582,912 kernel.img<br>
06-Jun-17  10:58 PM         4,194,304 kpanic.img<br>
06-Jun-17  10:58 PM         4,194,304 metadata.img<br>
07-Jun-17  06:12 PM         4,194,304 misc.img<br>
07-Jun-17  05:56 PM     8,589,934,592 userdata.img<br>
07-Jun-17  06:12 PM        15,466,496 recovery.img<br>
07-Jun-17  06:32 PM             2,491 rkdumper.txt<br>
07-Jun-17  06:15 PM     1,048,576,000 system.img<br>
07-Jun-17  06:27 PM     7,969,177,600 user.img<br>

The dumped user.img <br>
![1](https://raw.githubusercontent.com/kacos2000/Other/master/Minix/1.jpg)<br>

and userdata.img<br>
![2](https://raw.githubusercontent.com/kacos2000/Other/master/Minix/2.jpg)<br>

can be easily loaded in FTK imager or any other forensic tool.


 

 

