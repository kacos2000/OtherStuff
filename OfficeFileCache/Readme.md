
## Office Upload Center

**[OUCcentraltable2.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OUCcentraltable2.ps1)**: Powershell script to parse CentralTable.accdb Access db & FSF files from an OfficeFileCache folder. Exports output to .txt & .csv. 
*Requires Microsoft Access Database Engine ODBC driver (*script does a check*). If needed, you should install the x64 driver for 64-bit Windows, and x32 for 32-bit Windows from an elevated cmd prompt, using the "/Quiet" switch.* 

Complements [ArsenalRecon's](https://arsenalrecon.com/) **OSDrecon** (Office Document Cache FSD extractor/parser).

**[OUC-FSF.ps1](https://github.com/kacos2000/Other/blob/master/OfficeFileCache/OUC-FSF.ps1)**: Powershell script to parse the FSF files in an OfficeFileCache folder. CentralTable.accdb points to the GUID in the FSF filename, and the FSF contains the GUID of the respective File Store Data (FSD) container. Exports output to a .txt file 
