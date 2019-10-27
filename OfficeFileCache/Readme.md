
## Office Upload Center
<br>

 **[The Office Document Cache and Introducing ODC Recon – Part I ](https://arsenalrecon.com/2019/10/the-office-document-cache-and-introducing-odc-recon-part-i/)**
<br>
__________________________________________________________________________________________

  * **[OfficeFileCache.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeFileCache.exe)**: x64 GUI CentralTable.accdb, FSD & FSF viewer. Optionally exports output to csv.<br>
      * Requires [Microsoft Access Database Engine ODBC driver](https://www.microsoft.com/en-us/download/details.aspx?id=54920)<br> 
  
        ![OfficeFileCacheFSF.JPG](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeFileCacheFSF.JPG)
        ![OfficeFileCacheFSD.JPG](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeFileCacheFSD.JPG)
        ![OfficeFileCacheCT.JPG](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeFileCacheCT.JPG)
__________________________________________________________________________________________

  * **[ODCreconGUI.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCreconGUI.exe)**: x64 GUI for *[ArsenalRecon's](https://arsenalrecon.com/)* **ODCrecon64.exe**. Extracts OOXML documents from FSD files. Obviously, it requires ODCrecon64.exe ;-)<br>
  
       ![ODCreconGUI.JPG](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCreconGUI.JPG)

__________________________________________________________________________________________

  * **[ODCreg.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODCreg.ps1)**: Powershell script to parse an NTuser.dat hive file for Microsoft Office roaming Metadata *(Microsoft/Sharepoint IDs, files opened from Skydrive/Sharepoint & related timestamps)*. Exports output to a .txt csv file. Requires to be run as Administrator<br>
__________________________________________________________________________________________

  * **[ODC-FSD.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODC-FSD.exe)**: Parse the OfficeFileCache FSD files in a folder and get FSD size and filename & url of the embedded file. Exports output to a .txt file.<br>
__________________________________________________________________________________________

  * **[ODC-FSF.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/ODC-FSF.exe)**: Parse the OfficeFileCache FSF files in a folder and get the embedded FSD GUID. Exports output to a .txt file.<br>
__________________________________________________________________________________________

  * **[OneDrive.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OneDrive.ps1)**: Powershell script to list all MS Accounts associated with Onedrive, from a user's NTuser.dat. Requires to be run as Administrator<br>
__________________________________________________________________________________________

  * **[OfficeMRU.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OfficeMRU.ps1)**: Powershell script to list the most recently used (MRU) files/folders in MS Office applications, from a user's NTuser.dat. Requires to be run as Administrator<br>
__________________________________________________________________________________________

  * **[MruServiceCache.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/MruServiceCache.ps1)**: Powershell script to parse the contents of the json files in an 'MruServiceCache' folder *(Office16+ only)*<br>
  * **[MruServiceCache.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/MruServiceCache.exe)**: Same as a standalone exe.<br>  
__________________________________________________________________________________________

  * **[Backstage.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/Backstage.ps1)**: Powershell script to parse the contents of the json files in a 'BackstageInAppNavCache' folder *(Office16+ only)*<br>
   * **[Backstagex64.exe](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/Backstagex64.exe)**: Same as a standalone exe.<br>
       [Blog post](http://www.learndfir.com/2018/10/18/daily-blog-510-office-2016-backstage-artifacts/), [Python Script](https://github.com/ArsenalRecon/BackstageParser)
   
__________________________________________________________________________________________

   - Note1: *The output exported from the above scripts are set to be saved as (csv) .txt files in the* `$env:TEMP` *folder.*
   - Note2: *The CentralTable.accdb points to the GUID in the FSF filename, and the FSF contains the GUID of the respective File Store Data (FSD) container.*
