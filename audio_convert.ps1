#
# PowerShell script to convert all FLAC audio files in a directory to another format
# Original script by z80Andrew (2024)
#

enum Formats
{
   FLAC
   ALAC
   OPUS
   MP3
}

## Configuration variables
##
$FFMpegPath = "C:\ffmpeg\ffmpeg.exe"
$InputPath = "C:\FLAC"
$OutputPath = "C:\Output"
$OutputFormat = [Formats]::OPUS
##

$InputExtension = ".flac"
$OutputExtension = ""
$ProcessedFilesCount = 0

$InputFiles = Get-ChildItem -LiteralPath $InputPath -File -Filter *$InputExtension -Recurse

$InputFilesCount = $InputFiles.Length

$Inputfiles | ForEach {
    $ProgressPercent = (100/$InputFilesCount) * $ProcessedFilesCount
    Write-Progress -Activity "Converting to $OutputFormat" -Status "$ProcessedFilesCount / $InputFilesCount processed" -PercentComplete $ProgressPercent
    
    $FileName = $_.BaseName
    $FullPath = $_.FullName
    $FilePath = $_.Directory.FullName.Replace($InputPath,'')
    $OutputFolderPath = Join-Path -Path $OutputPath -ChildPath $FilePath

    if(!([System.IO.DirectoryInfo]($OutputFolderPath)).Exists) {
        Write-Host "Creating Directory $($OutputFolderPath)"
        New-Item -Item Directory -Path $OutputFolderPath | Out-Null
    }

    $OutputFilePath = Join-Path -Path $OutputFolderPath -ChildPath $FileName

    Write-Host $_.FullName.Replace($InputPath,'')

    switch($OutputFormat)
    {
        ([Formats]::FLAC)
        {
            $OutputExtension = ".flac"
            &$FFMpegPath -i "$FullPath" -c:a flac -c:v copy "$OutputFilePath$OutputExtension" -compression_level 12 -y -hide_banner -loglevel error
            break
        }

        ([Formats]::OPUS)
        { 
            $OutputExtension = ".opus"
            &$FFMpegPath -i "$FullPath" -c:a libopus -c:v copy -vbr on -compression_level 10 -b:a 128K "$OutputFilePath$OutputExtension" -y -hide_banner -loglevel error
            break
        }
        
        ([Formats]::ALAC)
        {
            $OutputExtension = ".m4a"
            &$FFMpegPath -i "$FullPath" -c:a alac -c:v copy "$OutputFilePath$OutputExtension" -y -hide_banner -loglevel error
            break
        }

        ([Formats]::MP3)
        {
            # -q:a 3 is VBR at a target of 175kbit/s, see https://trac.ffmpeg.org/wiki/Encode/MP3
            $OutputExtension = ".mp3"
            &$FFMpegPath -i "$FullPath" -c:a libmp3lame -c:v copy -q:a 3 "$OutputFilePath$OutputExtension" -y -hide_banner -loglevel error
            break
        }
    }

    $ProcessedFilesCount = $ProcessedFilesCount + 1
}

Write-Progress -Activity "Conversion in progress" -Completed

Write-Host "Input files"
Write-Host $InputFilesCount
Write-Host "Output files"
Write-Host (Get-ChildItem -LiteralPath $OutputPath -File -Filter *$OutputExtension -Recurse).Length
