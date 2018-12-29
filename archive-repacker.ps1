#!C:\Windows\System32\powershell.exe
## Repackages all archives of certain types within a given directory.
## Copyright (C) from 2018 by Miles B Huff per LGPL3.
# @param args[0] The directory whose archives you'd like to repackage.
# @param args[1] If defined, inserts a pause after extraction for each archive.
#                This pause gives you the opportunity to modify the contents of
#                each archive before repackaging.
$CurrentDir = $(Get-Location)

## Decide on a target directory
################################################################################
$TargetRoot = ''
if(-not $null -eq $args[0]) {
    $TargetRoot = "$($args[0])"
} else {
    $TargetRoot = "$(Get-Location)"
}
Set-Location "$TargetRoot"

## Variables
################################################################################
$Exts = @('7z', 'zip')
$TempDir = 'Temp'

## Figure out what files to work with
################################################################################

## Find all the files
$Files = Get-ChildItem "."
for($f = 0; $f -lt $Files.Length; $f++) {

    ## Find the current file's extension
    $Ext = (Write-Output "$($Files[$f])" | Select-String -Pattern '\.') -Replace '^.*\.',''
    if('' -eq $ext) {continue}

    ## Filter out unsupported extensions
    for($x = 0; $x -lt $Exts.Length; $x++) {
        if($Ext -eq $Exts[$x]) {

            ## Build arguments
            ####################################################################
            $NPROC='12' #NOTE: Change this to the number of CPU cores you have.
            $ArchiverPath = ''
            $ExtractOpts  = @()
            $CompressOpts = @()
            switch($Exts[$x]) {
                '7z'  {
                    $ArchiverPath = "$PSScriptRoot\archivers\7z.exe"
                    $ExtractOpts  = @('x',"$($Files[$f])","-o$TempDir",'*','-y')
                    $CompressOpts = @('a',"$($Files[$f])",".\$TempDir\*",'-y','-r','-ssw','-slp','-stl',"-mmt=$NPROC",'-t7z' ,'-mm=LZMA2','-mx=9','-mfb=273','-md=128m','-mtc-','-mtm-','-mta-','-mf=off','-mmtf+','-mhc+','-ms+','-mqs+','-myx=9')
                }
                'zip' {
                    $ArchiverPath = "$PSScriptRoot\archivers\7z.exe"
                    $ExtractOpts  = @('x',"$($Files[$f])","-o$TempDir",'*','-y')
                    $CompressOpts = @('a',"$($Files[$f])",".\$TempDir\*",'-y','-r','-ssw','-slp','-stl',"-mmt=$NPROC",'-tzip','-mm=LZMA' ,'-mx=9','-mfb=273','-md=128m','-mtc-')
                }
                'rar' {
                    $ArchiverPath = "$PSScriptRoot\archivers\rar.exe"
                    $ExtractOpts  = @()
                    $CompressOpts = @()
                }
            }
            if(('' -eq $ArchiverPath) -or (@() -eq $CompressOpts) -or (@() -eq $ExtractOpts)) {continue}

            ## Repackage
            ####################################################################
            Clear-Host

            ## Check temp dir
            if(Test-Path "$TempDir") {Remove-Item -Recurse -Force "$TempDir"}
            mkdir "$TempDir"

            ## Extract
            & $ArchiverPath $ExtractOpts
            Remove-Item -Recurse -Force "$($Files[$f])"

            ## Pause so that the user can interact with the contents
            if(-not $null -eq $args[1]) {
                Write-Host -NoNewLine "Please inspect the archive at $TargetRoot\$TempDir. Press any key to continue.";
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
            }
            
            ## Compress
            & $ArchiverPath $CompressOpts
            Remove-Item -Recurse -Force "$TempDir"
        }
    }
}
Set-Location "$CurrentDir"
