# CopyADGroupMembership
The purpose of this script is to copy a users AD group membership to another user. 

## Input
 - Parameter: SourceUser (optional) - The user to copy group membership **from**.  
    >If no source user is specified, the script will search for a user with samaccountname like "template*" in the targer users' OU and copy the group membership of that user.
 - Parameter: TargetUser - The user to copy group membership **to**.
 - Parameter: Filter - Only add target user to a subset of source users' groups (wildcards supported).

## Running
 - The script should be run on a server with ActiveDirectory powershell modules (DC, Exchange server)
 - Script will start as soon as it's run without confimation.