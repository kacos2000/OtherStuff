
## Office Upload Center
__________________________________________________________________________________________

  * **[ODCfilecache.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCfilecache.ps1)**: Powershell script to parse CentralTable.accdb Access db *(filenames, GUIDs, Timestamps)*, FSD & FSF files from an OfficeFileCache folder. 
Exports output to .txt & .csv.<br> 
If you do not have *[ArsenalRecon's](https://arsenalrecon.com/)* **ODCrecon** press `Cancel` in the second File Open Window <br>

     
     * Requires [Microsoft Access Database Engine ODBC driver](https://www.microsoft.com/en-us/download/details.aspx?id=54920) (*script does a check*). If needed, you should install the x64 driver for 64-bit Windows, or x32 driver for 32-bit Windows from an elevated cmd prompt, using the `/Quiet` switch.<br>
     * FSD Extraction requires *[ArsenalRecon's](https://arsenalrecon.com/)* ODCrecon tool.<br>
__________________________________________________________________________________________

  * **[ODCreg.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCreg.ps1)**: Powershell script to parse an NTuser.dat hive file for Microsoft Office roaming Metadata *(Microsoft/Sharepoint IDs, files opened from Skydrive/Sharepoint $ related timestamps)*. Exports output to a .txt csv file. Requires to be run as Administrator<br>
__________________________________________________________________________________________

  * **[OUC-FSF.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OUC-FSF.ps1)**: Powershell standlone script to parse the FSF files in an OfficeFileCache folder. Exports output to a .txt file.<br>
__________________________________________________________________________________________

* **[OneDrive.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OneDrive.ps1)**: Powershell script to list all MS Accounts associated with Onedrive, from a user's NTuser.dat. Requires to be run as Administrator<br>
__________________________________________________________________________________________

* **[OfficeMRU.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeMRU.ps1)**: Powershell script to list the most recently used (MRU) files/folders in MS Office applications, from a user's NTuser.dat. Requires to be run as Administrator<br>
__________________________________________________________________________________________

* **[MruServiceCache.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/MruServiceCache.ps1)**: Powershell script to parse the contents of the json files in the MruServiceCache folder<br>
__________________________________________________________________________________________


   - Note1: *The files exported from the above scripts are set to be saved at the* `$env:TEMP` *folder.*
   - Note2: *The CentralTable.accdb points to the GUID in the FSF filename, and the FSF contains the GUID of the respective File Store Data (FSD) container.*
