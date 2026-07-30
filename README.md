# PowerShell-NamedPipe_Client
Windows PowerShell Library for IPC Named Pipe Client

This PowerShell script functions as an includable library to add functions related to Named Pipe operations. 
At the moment, this is for a "Pull" type pipe, where the client asks the server for data, and then waits for a response before submitting more data.

Includes a helper function Convert-ToAsciiSafe, which removes diacritics and non-printable ASCII.

## Example Code
1. To run the example, place a version of NamedPipe_Client_v#.#.ps1 into the same directory as the example scripts.
2. Open up two separate PowerShell windows in the directory.
3. Run the EchoServer in one window first, then the Client in the other window, second.
4. Don't forget to use the format 'powershell -ExecutionPolicy Bypass -File ####.ps1' for each one if you have problems starting.

## Pipe Communications Variables
 - $Global:NamedPipe_Server_Name (default: 'Select') : This will be set to the name of the Pipe named in the Named Pipe Server. If it is 'Select', then a list of available pipes will be displayed during startup for the user to select manually
 - $Global:NamedPipe_Server_Process (default: 'Process') : This is the name of the application hosting the Named Pipe Server
 - $Global:NamedPipe_Server_ResponseDelay (default 57ms) : This is how long the Pull command will wait after a Write to Read a response
## Additional functional global variables
 - $Global:NamedPipe_Client_AvailablePipeSelection_Filter : (T/F) Enable Filtering of available Windows Pipes
 - $Global:NamedPipe_Client_AutomaticallySelectUniqueFilteredPipeServerName = T/F (If there is exactly only one pipe name after the filtering, automatically select it)
 - $Global:NamedPipe_Client_AvailablePipeSelection_NamePattern : RegEx filter for desired pipe name list

## Future Planned Changes
 - Graphical interface maybe

## Known Bugs / Issues
 - Haven't rigorously tested reconnects

## Versioning
 - v1.11 - Added pipe selection from a list of available pipes
 - v1.10 - Changed Startup Script to run more automatically
 - v1.1 - Changed names, made functions return values

## Example
 - The example files include a sample Named Pipe Echo-server that pairs with the Client program.
 - Put the library in the same folder as the Client and Server scripts.
 - Execute the Server in a different Powershell window than the client.
 - The Client can open the named pipe, and the server will send back any data sent to it.
