#
# PowerShell script to convert all FLAC audio files in a directory to another format
# Original script by z80Andrew (2024)
#

enum Formats
{
   ALAC
   OPUS
   MP3
}

## Configuration variables
##
$FFMpegPath = "C:\ffmpeg\ffmpeg.exe"
$InputPath = "C:\input_folder"
$OutputPath = "C:\output_folder"
$OutputFormat = [Formats]::MP3
##

$OutputExtension = ""
$ProcessedFilesCount = 0

$InputFiles = Get-ChildItem -Path $InputPath -File -Filter *.flac -Recurse

$InputFilesCount = $InputFiles.Length

$Inputfiles | ForEach {
    $ProgressPercent = (100/$InputFilesCount) * $ProcessedFilesCount
    Write-Progress -Activity "Conversion in progress" -Status "$ProcessedFilesCount / $InputFilesCount processed" -PercentComplete $ProgressPercent
    
    $FileName = $_.BaseName
    $FullPath = $_.FullName
    $FilePath = $_.Directory.FullName.Replace($InputPath,'')
    $NewPath = "$($OutputPath)$($FilePath)"

    if(!([System.IO.DirectoryInfo]($NewPath)).Exists) {
        Write-Host "Creating Directory $($NewPath)"
        New-Item -Item Directory -Path $NewPath | Out-Null
    }

    Write-Host $_.FullName.Replace($InputPath,'')

    switch($OutputFormat)
    {
        ([Formats]::OPUS)
        { 
            $OutputExtension = ".opus"
            &$FFMpegPath -i "$FullPath" -c:a libopus -c:v copy -vbr on -compression_level 10 -b:a 192K "$NewPath\$FileName$OutputExtension" -y -hide_banner -loglevel error
            break
        }
        
        ([Formats]::ALAC)
        {
            $OutputExtension = ".m4a"
            &$FFMpegPath -i "$FullPath" -c:a alac -c:v copy "$NewPath\$FileName$OutputExtension" -y -hide_banner -loglevel error
            break
        }

        ([Formats]::MP3)
        {
            # -q:a 3 is VBR at a target 175kbit/s, see https://trac.ffmpeg.org/wiki/Encode/MP3
            $OutputExtension = ".mp3"
            &$FFMpegPath -i "$FullPath" -c:a libmp3lame -c:v copy -q:a 3 "$NewPath\$FileName$OutputExtension" -y -hide_banner -loglevel error
            break
        }
    }

    $ProcessedFilesCount = $ProcessedFilesCount + 1
}

Write-Progress -Activity "Conversion in progress" -Completed

Write-Host "Input files"
Write-Host $InputFilesCount
Write-Host "Output files"
Write-Host (Get-ChildItem -Path $OutputPath -File -Filter *$OutputExtension -Recurse).Length