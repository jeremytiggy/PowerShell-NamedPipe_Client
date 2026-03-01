Write-Host "[WindowsIPCNamedPipeClient] Loading library..." -ForegroundColor Gray
# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Windows IPC Named Pipe Client Definitions ---------------------------------
# Import Windows API function for non-blocking pipe check
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class PipeUtils {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool PeekNamedPipe(
        IntPtr hNamedPipe,
        byte[] lpBuffer,
        uint nBufferSize,
        out uint lpBytesRead,
        out uint lpTotalBytesAvail,
        out uint lpBytesLeftThisMessage);
}
"@
Write-Host "[WindowsIPCNamedPipeClient] function TypeDefinition registered" -ForegroundColor Green
function Convert-ToAsciiSafe {
    param (
        [string]$InputString
    )

    if ([string]::IsNullOrWhiteSpace($InputString)) {
        return ''
    }

    # Normalize & strip diacritics
    $normalized = $InputString.Normalize([Text.NormalizationForm]::FormD)
    $ascii = -join ($normalized.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark'
    })

    # Remove anything not printable ASCII
    $ascii = ($ascii -replace '[^ -~]', '').Trim()

    return $ascii
}
Write-Host "[WindowsIPCNamedPipeClient] function [string]Convert-ToAsciiSafe -[string]InputString" -ForegroundColor Green
# Pipe Parameters
$Global:pipeName = 'PipeName'
# Pipe Communications Variables
$Global:readData = ''
$Global:readData_available = $false
$Global:writeData = ''
$Global:peekBytes = -1
Write-Host "[WindowsIPCNamedPipeClient] Pipe Parameters registered" -ForegroundColor Green
# Pipe Communications Helper Functions
function PeekPipe {
	# Use Windows API to check for data without blocking
	$Global:peekBytes = -1
    $Global:readData_available = $false
	$bytesRead = 0
	$bytesAvailable = 0
	$bytesLeft = 0
	
	$success = [PipeUtils]::PeekNamedPipe(
		$Global:pipe.SafePipeHandle.DangerousGetHandle(),
		$null,
		0,
		[ref]$bytesRead,
		[ref]$bytesAvailable,
		[ref]$bytesLeft
	)
	
	if (-not $success) {
		$lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
		$Global:peekBytes = -1
        $Global:readData_available = $false
		return "[Pipe Peek Error]: Win32 error code $lastError"
	}
	if ($success -and $bytesAvailable -gt 0) {

		# Read the available data
		
		$Global:peekBytes = $bytesAvailable
		return "[Pipe Peek]: Found $bytesAvailable bytes available"
	}
	else {
		$Global:peekBytes = 0
		$Global:readData_available = $false
        return "[Pipe Peek]: Connected, but no data available (Bytes available: $bytesAvailable)"
	}

}
Write-Host "[WindowsIPCNamedPipeClient] function PeekPipe registered" -ForegroundColor Green
function ReadPipe {
	$Global:readData = ''
	$peekResultString = (PeekPipe)
	$bytesAvailable = $Global:peekBytes
	if ($bytesAvailable -gt 0) {

		# Read the available data
		$bytesRead = 0
		$buffer = New-Object byte[] $bytesAvailable
		$bytesRead = $Global:pipe.Read($buffer, 0, $bytesAvailable)
		
		if ($bytesRead -gt 0) {
			$response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
			$response = $response.Trim() -replace "`r|`n", ""
			$Global:readData = $response
            $Global:readData_available = $true
			return "[Pipe ReadData]: $Global:readData"
		}
		else {
			$Global:readData_available = $false
            return "[Pipe Read Error]: Failed to read data after successful peek"
		}
	}
	else {
		$Global:readData_available = $false
        return "[Pipe Read Error]: No data available (Bytes available: $bytesAvailable)"
	}
}
Write-Host "[WindowsIPCNamedPipeClient] function ReadPipe registered" -ForegroundColor Green
function WritePipe {
	$asciiWriteData = Convert-ToAsciiSafe -InputString $Global:writeData
    $Global:writer.WriteLine($asciiWriteData)
	$returnEcho = "[Pipe WriteData]: $asciiWriteData"
	
	$Global:writeData = ''
	
	# Optional: Check if we got an immediate response
    # 57 milliseconds is 2 ticks
	Start-Sleep -Milliseconds 57
	$peekResultString = (PeekPipe)
	$bytesAvailable = $Global:peekBytes
	

	$returnAvailable = ''
	if ($bytesAvailable -gt 0) {
		$returnAvailable = "`n[Pipe WriteData Notice]: Server responded with $bytesAvailable bytes"
	}
	return "$returnEcho$returnAvailable"
}
Write-Host "[WindowsIPCNamedPipeClient] function WritePipe registered" -ForegroundColor Green
function PullPipe {
	$asciiWriteData = Convert-ToAsciiSafe -InputString $Global:writeData
    $Global:writer.WriteLine($asciiWriteData)
	$returnEcho = "[Pipe Pull WriteData]: $asciiWriteData"
	# Write-Host $returnEcho
	$Global:writeData = ''
	
	# Wait for what should be an immediate response
	Start-Sleep -Milliseconds 57
	$ReadPipe_exitcode = (ReadPipe)
    # Write-Host ($ReadPipe_exitcode)
    if ($Global:readData_available) {
        return "[Pipe Pull ReadData]: $Global:readData"
    } else {
        return "[Pipe Pull ReadData]: No data received after write"
    }
}
Write-Host "[WindowsIPCNamedPipeClient] function PullPipe registered" -ForegroundColor Green
function OpenPipe {
    Write-Host "[OpenPipe]: Connecting to pipe: $Global:pipeName"
    $Global:pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.', $Global:pipeName, [System.IO.Pipes.PipeDirection]::InOut)
    $Global:pipe.Connect(5000)
    Write-Host "[OpenPipe]: Pipe $Global:pipeName Connected successfully!"
    $Global:writer = New-Object System.IO.StreamWriter($Global:pipe, [System.Text.Encoding]::ASCII)
    $Global:writer.AutoFlush = $true
}
Write-Host "[WindowsIPCNamedPipeClient] function OpenPipe registered" -ForegroundColor Green
# Windows IPC Named Pipe Client Definitions^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ------------------------------------------------------------------------------------------------------------------------------------------------------
# When using the Windows IPC Named Pipe Client, make sure to set $Global:pipeName to match the pipe name used
function WindowsIPCNamedPipeClient_loaded {
	Write-Host "[WindowsIPCNamedPipeClient] Windows IPC Named Pipe Client library loaded and ready to use." -ForegroundColor Green
}

Write-Host "[WindowsIPCNamedPipeClient] Library Loaded" -ForegroundColor Gray
