   _____                .__     ____________   ____.__               
  /     \ _____    ____ |  |__  \_____  \   \ /   /|__| ______  _  __
 /  \ /  \\__  \ _/ ___\|  |  \  /   |   \   Y   / |  |/ __ \ \/ \/ /
/    Y    \/ __ \\  \___|   Y  \/    |    \     /  |  \  ___/\     / 
\____|__  (____  /\___  >___|  /\_______  /\___/   |__|\___  >\/\_/  
        \/     \/     \/     \/         \/                 \/        

A fork from MachOView to update and fix some bugs, mostly Mountain Lion & iOS 6 related.
Also some small changes to the original behaviour.

Original MachOView by psaghelyi at http://sourceforge.net/projects/machoview/.
Thanks to psaghelyi for his great work :-)

Latest versions are Lion+ only.
The LLVM disassembler was replaced with Capstone. This eliminates Clang/LLVM packages requirements.
The downside is that Capstone stops disassembling on bad instructions which means that for now data in code and jump tables data will create problems and __text section disassembly might be incomplete in binaries that contain such data.
Capstone improved disassembly on error but data in code locations are available in header so this can and should be improved.

A static Capstone library extracted from the official DMG is included in the repo.
If you want to be safe you should download Capstone and compile it yourself.

Now features the attach option to analyse headers of a running process.
To use this feature you will need to codesign the binary.
Follow this LLDB guide to create the certificate and then codesign MachOView binary.
https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt
The necessary entitlements are already added to Info.plist.

Be warned that this allows MachOView to have task_for_pid() privs under current under and control
every process from user running it.
The whole Mach-O parsing code needs to be reviewed and made more robust.

Enjoy,
fG!