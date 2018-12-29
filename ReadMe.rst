ReadMe
================================================================================

Author
--------------------------------------------------------------------------------
All source code in this repository was written by Miles B Huff, is Copyright
(C) 2018 to him, and is licensed per the terms of the Lesser GNU General Public
License v3.0+.  The full terms of this license can be found at
``\Copyright.txt``.

Most of 7-Zip is also licensed under the LGPL, albeit v2.1+, rather than v3.0+.
The rest of 7-Zip is licensed under BSD3.  Please see
``Archivers\7-Zip Copyright.txt`` for more info.  Thanks for making such a great
program, Igor Pavlov!

About
--------------------------------------------------------------------------------
This repository contains a PowerShell script and the 64-bit PE binary of 7-Zip
v18.05's CLI tool.

Said PowerShell script finds every .7z and .zip file in a given directory, and
repacks them with a strong compression algorithm.  This can save a few hundred
megabytes in a power user's Downloads folder;  but where it really shines, is
when you use some sort of package manager or mod manager whose downloads use
less-than-stellar compression strengths.

As a case-in-point, I ran this script on each folder in
``%appdata%\Roaming\Vortex\Downloads``.  My SkyrimSE folder (minus .rar files)
went from 26.6GiBs, to 25.1GiBs -- a savings of 1.5GiBs, or about 6%!  While 6%
may not seem like much, there were several archives that were over 25% smaller
after recompression.  The reason the total number was 6% instead of 25%, is
because most of that 26.6GiBs was [thankfully] already maximally compressed.
Between Vortex's SkyrimSE and Skyrim downloads folders, and my user downloads
folder, I saved probably about 2GiBs of space without deleting anything.

"Why would anyone ever use a weak compression algorithm?", you might be
wondering. Well, there are actually times when a weaker compression algorithm is
useful -- typically for data that needs to be accessed frequently (A really good
example of a use-case for light compression, is transparent, partition-level
compression.).  But when you have a lot of archived data that you don't want to
delete and that's mostly just collecting dust, repackaging it with a stronger
compression algorithm can be a great thing to do.

Usage
--------------------------------------------------------------------------------
``Archive-Repacker.ps1 -Dir \path\ [-Pause|-Help]``

- ``-Dir`` is where you specify a directory whose archives you'd like to repack.
- ``-Pause`` makes the script pause after each extraction.  This can be very
  useful -- you can use this break period to run texture optimizers, for example.
  This can save you even more space.
- ``-Help`` prints help text.

If you don't know how to run PowerShell scripts, there are many tutorials out
there on the Internet -- you need only search.
One such tutorial may be found here:
https://stackoverflow.com/questions/2035193/how-to-run-a-powershell-script.

Notes
--------------------------------------------------------------------------------
If you're still using a 32-bit OS, you'll need to download a 32-bit version of
7z.exe.  The latest can be found here: https://www.7-zip.org/download.html.

The way this script is currently configured, the contents of each archive will
lose their modification dates.  This gets a marginally better compression ratio.
While this may be okay for end-users, it is not likely so for mod authors.  If
you are using this script to optimize your own archive, you can make it preserve
modification dates by removing all instances of ``,'-mtc-'``.

If you would like to create archives with these settings without having to use
this script, you can configure the 7-Zip File Manager to create just-as-strongly
compressed archives.  To do this, create a new archive, and use the following
options:

- Archive format: .7z
- Compression level: Ultra
- Compression method: LZMA2
- Dictionary size: 128 MB
  (You may need to reduce this if you don't have much RAM.  With a 128MB DS, I
  was using roughly 4GiBs of RAM for each large archive.)
  (Note that 128MB is the maximum for 32-bit computers.)
- Word size: 273
  (Afaik, there's no reason not to use the maximum, here.)
- Solid Block size: Solid
  (This makes a *huge* difference.)

Request to Archive Creators
--------------------------------------------------------------------------------
If you are creating an archive that you intend to ship over the Internet, please
use a strong form of compression.  Using weak compression algorithms (1) wastes
bandwidth (This costs hosts and users alike extra money.), (2) makes downloads
slower, and (3) wastes disk-space for both server hosts and end-users.

When creating archives, please do not use proprietary formats like .rar.  These
formats are (1) usually inferior in performance and compression ratios to
Free/Libre formats like .7z, and (2) these formats cannot be created by
Free/Libre archivers, like 7z.  Moving everything to a standard of .7z or .zip
on Windows will make everyone's lives easier.

Future Expansion
--------------------------------------------------------------------------------
As I use Linux more often than Windows (at least at home), it's likely that I'll
eventually make a bash version of this script.  If and when I do, I might even
try to get it on the AUR -- we'll just have to see.  The bash version will
likely support more compression algorithms than the PowerShell version, since I
won't have to ship their binaries with the script.

I might add the option to only look at files modified after a certain date.
This way, you can re-run the script on the same directory, without wasting time
repacking already-optimized archives.  This will require the removal of the
``-stl`` option, which sets the archive's modification date to that of its
files.

This script is unlikely to gain support for .rar files.  If I do ever add
support, I will probably be unable to include the binary for the rar archiver,
due to its proprietary license.
