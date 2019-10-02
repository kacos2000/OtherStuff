
## Office Upload Center
__________________________________________________________________________________________

  * **[ODCfilecache.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCfilecache.ps1)**: Powershell script to parse CentralTable.accdb Access db *(filenames, GUIDs, Timestamps)*, FSD & FSF files from an OfficeFileCache folder. 
Exports output to .txt & .csv.<br> 
If you do not have *[ArsenalRecon's](https://arsenalrecon.com/)* **OSDrecon** press `Cancel` in the second File Open Window <br>

     *Requires [Microsoft Access Database Engine ODBC driver](https://www.microsoft.com/en-us/download/details.aspx?id=54920) (*script does a check*). If needed, you should install the x64 driver for 64-bit Windows, and x32 for 32-bit Windows from an elevated cmd prompt, using the `/Quiet` switch.
__________________________________________________________________________________________

  * **[ODCreg.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OUCreg.ps1)**: Powershell script to parse an NTuser.dat hive file for Microsoft Office roaming Metadata *(Microsoft/Sharepoint IDs, files opened from Skydrive/Sharepoint $ related timestamps)*. Exports output to a .txt csv file. Requires to be run as Administrator<br>

    * Note: *Due to a bug yet to be solved, the mounted hive does not unload automatically. You may need to close the Powershell terminal, open a new one and  type `reg unload HKEY_LOCAL_MACHINE\Temp`.*
__________________________________________________________________________________________

  * **[OUC-FSF.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OUC-FSF.ps1)**: Powershell standlone script to parse the FSF files in an OfficeFileCache folder. Exports output to a .txt file.<br>
__________________________________________________________________________________________

   - Note1: *The files exported from the above scripts are set to be saved at the* `$env:TEMP` *folder.*
   - Note2: *The CentralTable.accdb points to the GUID in the FSF filename, and the FSF contains the GUID of the respective File Store Data (FSD) container.*
  __________________________________________________________________________________________
 

