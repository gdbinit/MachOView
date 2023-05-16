```
   _____                .__     ____________   ____.__               
  /     \ _____    ____ |  |__  \_____  \   \ /   /|__| ______  _  __
 /  \ /  \\__  \ _/ ___\|  |  \  /   |   \   Y   / |  |/ __ \ \/ \/ /
/    Y    \/ __ \\  \___|   Y  \/    |    \     /  |  \  ___/\     / 
\____|__  (____  /\___  >___|  /\_______  /\___/   |__|\___  >\/\_/  
        \/     \/     \/     \/         \/                 \/        
```

## Update - 16/05/2023

This code has return from the dead and updated to version 3.0. 

Version 3.0 is now a x86_64/arm64 universal binary, with 10.13+ as the minimum version.

Building has been tested with Xcode 13 or higher. The best option is to build with latest available Xcode (14.3) and SDK since I stopped including local copies of latest headers and using the system ones as much as possible. It's annoying to have to use latest version to have all features, but also annoying to keep those headers in sync. This time opting for latest version way.

Besides the universal binary, some bug fixes and small updates were merged, warnings were fixed (and then I found psaghelyi had also done this modernization effort 4 years ago), and Capstone has been updated to next branch to benefit from aarch64 updates. I haven't merged the modern Objective-C syntax since I find it a bit meh. Something I'm thinking of changing is the indent since I'm not a fan of 2 spaces.

### What's the future for this fork and project?

Over the last years I have been puzzled how people kept forking and staring this project on my GitHub despite being dead. I'm using Apple Silicon more often and missed this tool so decided to give it some love again.

There is still a lot of work ahead to make it better, mostly adding parsing for new and old commands that doesn't exist, and more important for me, making the mach-o parsing way more robust than it is.

I'm still divided on the latter. Blacktop has a nice Go based mach-o parser called [go-macho](https://github.com/blacktop/go-macho) and some months ago I was working on my own fork of it, where I changed the API a bit according to personal taste and more important made the parser a lot more robust (most of the time I'm dealing with potentially hostile binaries so parser security is very important to me). I'm thinking about the possibility of using a sandboxed Go backend and remove all the parsing code from the current codebase. This would be a more secure design and avoid the tedious and error-prone work of fixing the current code. Plus it has the benefit of using a modern codebase that can parse a lot more than the engine being used here right now. 

I also have to think about providing binary builds or not since I don't own right now a developer certificate and not counting on getting one and pay Apple's developer tax. 

Have fun,  
fG!

---

A fork from MachOView to update and fix some bugs, mostly Mountain Lion & iOS 6 related.  
Also some small changes to the original behaviour.

Original MachOView by psaghelyi at [machoview](https://sourceforge.net/projects/machoview/).  
Thanks to psaghelyi for his great work :-)

Latest versions are Lion+ only.  
The LLVM disassembler was replaced with Capstone. This eliminates Clang/LLVM packages requirements.  
The downside is that Capstone stops disassembling on bad instructions which means that for now data in code and jump tables data will create problems and `__text` section disassembly might be incomplete in binaries that contain such data.  
Capstone improved disassembly on error but data in code locations are available in header so this can and should be improved.

A static Capstone library extracted from the official DMG is included in the repo.  
If you want to be safe you should download Capstone and compile it yourself.

Now features the attach option to analyse headers of a running process.  
To use this feature you will need to codesign the binary.  
Follow this [LLDB guide](https://lldb.llvm.org/resources/build.html?highlight=codesign#code-signing-on-macos) to create the certificate and then codesign MachOView binary.  

The necessary entitlements are already added to Info.plist.

Be warned that this allows MachOView to have task_for_pid() privs under current under and control every process from user running it.  
The whole Mach-O parsing code needs to be reviewed and made more robust.

Enjoy,  
fG!

Note:
This repo is frozen in time and there are kinda active forks out there.  
The main problem of this codebase is that the Mach-O parser has quite some problems
and needs a significant overhaul to make it more robust and secure.  
I do have much better code but it's under NDAs etc and I don't have energy to reinvent
the wheel once again. Secure executable binary parsing is a ton of work in C/C++.  
It's possible but it's exhausting.
