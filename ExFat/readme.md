### Powershell script to show the [Allocated Clusters](https://github.com/kacos2000/Other/blob/master/ExFat/ExF_Bitmap.ps1) from an ExFAT $Bitmap 


Console Output:<br>
![console](https://raw.githubusercontent.com/kacos2000/Other/master/ExFat/bit0.JPG)

Each byte value represents the allocation status for 8 clusters. Translated to binary, each bit, starting from right to left is the allocation status switch for one cluster. So the Hex value 0xF0, of offset 0x09, is represented in binary 111110000 and accordingly: 


bit |	1 |	1 |	1 |	1 |	0 |	0 |	0 |	0
:----: | :----: | :----: | :----: | :----: | :----: | :----: | :----: | :----: 
cluster |	81 |	80 |	79 |	78 |	77 |	76 |	75 |	74
status | in use |	in use |	in use |	in use |	free |	free |	free |	free

so we get:<br>

Popup Window Output *(listing of all allocated clusters)*:<br>
![window](https://raw.githubusercontent.com/kacos2000/Other/master/ExFat/bit1.JPG)
*Note: I ordered the Cluster (#1-#8) in numerical order for easier viewing.* 




The total allocated cluster count:<br>
![window](https://raw.githubusercontent.com/kacos2000/Other/master/ExFat/bit2.JPG) 

plus the free cluster count *(FTK imager)*:<br>

![window](https://raw.githubusercontent.com/kacos2000/Other/master/ExFat/bit3.JPG)

Match the total number of clusters:<br>
![window](https://raw.githubusercontent.com/kacos2000/Other/master/ExFat/bit4.JPG) 




*References:*<br>
[Reverse Engineering the Microsoft exFAT File System](https://www.sans.org/reading-room/whitepapers/forensics/reverse-engineering-microsoft-exfat-file-system-33274) *(pages 42-44)*<br>
[The Extended FAT file system](https://events.static.linuxfound.org/images/stories/pdf/lceu11_munegowda_s.pdf) *(slide 14)*<br>
[]()
