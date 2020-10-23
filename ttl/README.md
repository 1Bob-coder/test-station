# ttl
### Tera Term Language files
The ttl directory holds the various ttl macro files used by TeraTerm.
The ttl macros are scripts that send and receive messages through the serial port
and support automated testing requirements.

Note:  Since the ttl macros use the specified com port as given with the TeraTerm
command, no other programs can have that com port open or it won't connect.

Some of the macros defined are:

flash.ttl - This macro does an nfs mount to the remote repository, then uses the
package loader utility developed by Shaw to flash the file into the box.

ast.ttl - This macro will execute an 'ast' command, capture the log, and exit when the
word 'Done' or a timeout appears (whichever comes first).

The 'ast' commands are defined as:

DmStats(Dm)                      - Demux statistics
SfStats(Sf)                      - Section Filter statistics
TunerStats(Tu)                   - Tuner statistics
SystemStats(Sys)                 - System statistics
HwStats(Hw)                      - Hw statistics
VideoStats(Vi)                   - Video statistics
AudioStats(Au)                   - Audio statistics
VcoStats(Vco)                    - VCO statistics
Hdmi <CMD>                       - HDMI commands: stats, reset
SysTimeStats(Time)               - SystemTime statistics
DlStats(Dl)                      - Download statistics
CcStats(Cc)                      - Cc statistics
ChanStats(Chan) <VALUE>          - Channel statistics, 0 for all channels'
VctStats(Vct) <VALUE>            - VCT statistics, 0 for all channels
CdtStats(Cdt)                    - CDT statistics
MmtStats(Mmt)                    - MMT statistics
TdtStats(Tdt)                    - TDT statistics
StsStats(Sts)                    - STS statistics
SvcHelperStats(Svc)                      - SVC HELPER statistics
SEA <VALUE>                      - SetEnableApps <module(s)>: enter blank to print options (eg. ca sf)
SES <VALUE>                      - SetEnableSeverity <level>: 1 (debug), 2 (info), 3 (notice), 4 (warning) or 5 (fatal)
GEA                              - GetEnableApps module(s)
GES                              - GetEnableSeverity level
