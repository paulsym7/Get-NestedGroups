Function Get-NestedGroup {
<#
.Synopsis
   This function will discover which security groups contain other groups as members and output a list of these groups.
.DESCRIPTION
   This function will discover which security groups contain other groups as members and output a list of these groups. Any security groups found as members will in turn be searched to check if they have any security groups as members.
   By default this function will output a list of nested groups found, use the -DisplayParent parameter switch to output a hash table of nested groups and their parent group.
.EXAMPLE
   Get-NestedGroup -GroupName SecurityGroup1

   This command will output a list of all nested groups found as members of SecurityGroup1
.EXAMPLE
   Get-NestedGroup -GroupName SecurityGroup1 -DisplayParent

   This command will output a hash table of all nested groups and their parent group that are found as membets of SecurityGroup1
#>

    [CmdletBinding()]
    Param(
        # Name of the security group to search for any nested group(s)
        [Parameter(Mandatory = $True)]
        [string]$GroupName,

        # Output the nested group name and the parent group instead of just the nested group(s)
        [switch]$DisplayParent
    )

    $NestedGroups = New-Object System.Collections.ArrayList
    # Get list of AD group members, this will include users as well as groups
    $members = (Get-ADGroup -Identity $GroupName -Properties Members).Members
    foreach($member in $members){
        try{
            # Add any groups found into the $NestedGroups array and search these groups for any nested groups within them
            $NestedGroup = Get-ADGroup -Identity $member.Split(',')[0].Replace('CN=','') -ErrorAction Stop
            If($DisplayParent){
                Get-NestedGroup -GroupName $NestedGroup.Name -DisplayParent
                $NestedGroups.Add(@{GroupName = $NestedGroup.Name
                                    Parent = $GroupName}) | Out-Null
            }
            Else{
                Get-NestedGroup -GroupName $NestedGroup.Name
                $NestedGroups.Add($NestedGroup.Name) | Out-Null
            }
        }
        catch{
            # $member was not a group, no action needed
        }
    }

    $NestedGroups
}