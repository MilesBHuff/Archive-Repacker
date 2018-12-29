#!C:\Windows\System32\powershell.exe
################################################################################
## Repackages all archives of certain types within a given directory.
# @param $Dir   The directory whose archives you'd like to repackage.
# @param $Pause If true, inserts a pause after extraction for each archive.
#               This pause gives you the opportunity to modify the contents of
#               each archive before repackaging.
# @param $Help  If true, displays help text.
################################################################################
## Copyright (C) from 2018 by Miles B Huff per LGPL3.
## This program is free software: you can redistribute it and/or modify
## it under the terms of the Lesser GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## Lesser GNU General Public License for more details.
## You should have received a copy of the Lesser GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
################################################################################
Param(
	[string] $Dir   = $Null,
	[switch] $Pause = $False,
	[switch] $Help  = $False
)

## Help text
################################################################################
Function Help {
	Write-Host 'Archive Repacker v1.1.0'
	Write-Host 
	Write-Host ':: Copyright'
	Write-Host 'Copyright (C) from 2018 by Miles B Huff per LGPL3.'
	Write-Host 'This program comes with ABSOLUTELY NO WARRANTY.'
	Write-Host 'This is free software, and you are welcome to redistribute it'
	Write-Host 'under certain conditions; see Copyright.txt for details.'
	Write-Host 
	Write-Host ':: Usage'
	Write-Host '$ Archive-Repacker.ps1 -Dir \path\ [-Pause|-Help]'
	Write-Host "-Dir   | The directory whose archives you'd like to repackage."
	Write-Host '-Pause | Pause after each extraction.'
	Write-Host '-Help  | Display this help text.'
	Write-Host 
}
If($Help) {
	Help
	Exit 0
}

## Verify input
################################################################################
If(($Null -Eq "$Dir") -Or ('' -Eq "$Dir") -Or (-Not (Test-Path "$Dir"))) {
	Write-Host ':: ERROR: Invalid path!'
	Write-Host
	Help
	Exit 1
}

## Variables
################################################################################
$Exts      = @('7z', 'zip') #,rar
$TempDir   = 'Temp'
$StartDir  = $(Get-Location)
$NProc     = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
$FastBytes = '273' ## The maximal value possible.
## Figure out how much RAM we have.
$RawRAM  = (Get-WmiObject -Class Win32_PhysicalMemory).Capacity
$RAM     = 0
For(  $i = 0; $i -Eq $RawRAM.Length; i++) {
	$RAM+= $RawRAM[$i]
}
## Determine the dictionary size, per a sketched interpretation of 7zFM's recommendations.
      If($RAM -Gt 12884901888) { ## 12GiB (Not really recommended to go higher.)
	$DictSize = '128m'
} ElseIf($RAM -Gt 10737418240) { ## 10GiB
	$DictSize = '96m'
} ElseIf($RAM -Gt  8589934592) { ##  8GiB
	$DictSize = '64m'
} ElseIf($RAM -Gt  6442450944) { ##  6GiB
	$DictSize = '48m'
} ElseIf($RAM -Gt  4294967296) { ##  4GiB
	$DictSize = '32m'
} ElseIf($RAM -Gt  2147483648) { ##  2GiB
	$DictSize = '16m'
} ElseIf($RAM -Gt  1073741824) { ##  1GiB
	$DictSize =  '8m'
} Else {                         ##512MiB
	$DictSize =  '3m'
}

## Figure out what files to work with
################################################################################
Set-Location "$Dir"

## Find all the files
$Files = Get-ChildItem "."
For($f = 0; $f -Lt $Files.Length; $f++) {

	## Find the current file's extension
	$Ext = (Write-Output "$($Files[$f])" | Select-String -Pattern '\.') -Replace '^.*\.',''
	If('' -Eq $Ext) {Continue}

	## Filter out unsupported extensions
	For($x = 0; $x -Lt $Exts.Length; $x++) {
		If($Ext -Eq $Exts[$x]) {

			## Build arguments
			####################################################################
			$ArchiverPath = ''
			$ExtractOpts  = @()
			$CompressOpts = @()
			switch($Exts[$x]) {
				'7z'  {
					$ArchiverPath = "$PSScriptRoot\Archivers\7z.exe"
					$ExtractOpts  = @('x',"$($Files[$f])","-o$TempDir",'*','-y')
					$CompressOpts = @('a',"$($Files[$f])",".\$TempDir\*",'-y','-r','-ssw','-slp','-stl',"-mmt=$NProc",'-t7z' ,'-mm=LZMA2','-mx=9',"-mfb=$FastBytes","-md=$DictSize",'-mtc-','-mtm-','-mta-','-mf=off','-mmtf+','-mhc+','-ms+','-mqs+','-myx=9')
				}
				'zip' {
					$ArchiverPath = "$PSScriptRoot\Archivers\7z.exe"
					$ExtractOpts  = @('x',"$($Files[$f])","-o$TempDir",'*','-y')
					$CompressOpts = @('a',"$($Files[$f])",".\$TempDir\*",'-y','-r','-ssw','-slp','-stl',"-mmt=$NProc",'-tzip','-mm=LZMA' ,'-mx=9',"-mfb=$FastBytes","-md=$DictSize",'-mtc-')
				}
				'rar' {
					$ArchiverPath = "$PSScriptRoot\Archivers\rar.exe"
					$ExtractOpts  = @()
					$CompressOpts = @()
				}
			}
			If(('' -Eq $ArchiverPath) -Or (@() -Eq $CompressOpts) -Or (@() -Eq $ExtractOpts)) {Continue}

			## Repackage
			####################################################################
			#Clear-Host

			## Check temp dir
			If(Test-Path "$TempDir") {Remove-Item -Recurse -Force "$TempDir"}
			mkdir "$TempDir"

			## Extract
			& $ArchiverPath $ExtractOpts
			Remove-Item -Recurse -Force "$($Files[$f])"

			## Pause so that the user can interact with the contents
			If(-not $Null -eq $args[1]) {
				Write-Host -NoNewLine "Please inspect the archive at $Dir\$TempDir. Press any key to continue.";
				$Null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
			}
			
			## Compress
			& $ArchiverPath $CompressOpts
			Remove-Item -Recurse -Force "$TempDir"
		}
	}
}
Set-Location "$StartDir"
