# o365recon - retrieve information on o365 accounts
#
# 2018, 2017 @nyxgeek, @Spoonman1091 - TrustedSec
#
# Requirements: 
# -Install Microsoft On-line Services Sign-In Assistant for IT Professionals RTW
#        https://www.microsoft.com/en-us/download/details.aspx?id=41950
# Then run "Install-Module MsOnline"
#


## FLAGS
# -U               Get Userlist
# -users_detailed  Get detailed information for each user
# -users_ldap      Pull down user list in ldap style format
# -G               Get Group list
# -M               Get Group Membership
# -D               Get Domain list
# -C               Get Company info

# -all             Do simple enum - like enum4linux (-U -G -M -D -C). This is run if no other options are selected.
# -outputfile      Output file prefix


param([switch] $U = $false, 
      [switch] $users_detailed = $false,
      [switch] $users_ldap = $false,
      [switch] $G = $false,
      [switch] $M = $false,
      [switch] $D = $false,
      [switch] $C = $false,
      [switch] $all = $false,
      [string] $outputfile = $false
      )


# check to see if -all is goingto be run either by default or choice
if ( (($U -eq $false) -And ($G -eq $false) -And ($users_detailed -eq $false) -And ($users_ldap -eq $false) -And ($M -eq $false) -And ($D -eq $false) -And ($C -eq $false)) -Or ($all -eq $true) ){

    echo "Running the -all flag"

    # set the flags to true
    $U = $true
    $G = $true
    $M = $true
    $D = $true
    $C = $true

}


# if we don't have an -outputfile name specified, then ask for one
if ($outputfile -eq $false){
#$CURRENTJOB=read-host "enter name for current job"

$projectname = Read-host -prompt "Please enter a project name"
$inputclean = '[^a-zA-Z]'
$projectname.Replace($inputclean,'')


} else{

#otherwise, set currentjob to the supplied outputfile name
$projectname = $outputfile
$inputclean = '[^a-zA-Z]'
$projectname.Replace($inputclean,'')
}

md $projectname
$CURRENTJOB = "./${projectname}/${projectname}"


######### NOW, DOWN TO BUSINESS ###########


#connect to MsolService
#try {
    #old way
    Connect-MsolService -ErrorAction Stop
    
    #new way - to be switched over soon
    #Connect-AzureAD

#}catch{
#    echo "Could not connect!"
#    throw $_
#  }




## COMPANYINFO - ON BY DEFAULT

#get company info
echo "Retrieving Company Info:"

#old way
Get-MsolCompanyInformation |  tee -FilePath .\${CURRENTJOB}.CompanyInfo.txt

#new way
#????

echo "-------------------------------------------"


## DOMAININFO FLAG - ON BY DEFAULT


#get other domain info
echo "Retrieving Domain Information:"

#old way
Get-MsolDomain | ft -Auto | tee -FilePath .\${CURRENTJOB}.Domains.txt

#new way
#Get-AzureADDomain | ft

echo "-------------------------------------------"

## USERS FLAG -- ON BY DEFAULT

Get-MsolUser -All | ft -Property UserPrincipalName -Autosize | Out-file -FilePath ./${CURRENTJOB}.Users.txt

echo "-------------------------------------------"

## IF DETAILED FLAG IS SET

Get-MsolUser -All |  Where-Object {$_.UserPrincipalName -notlike "HealthMailbox*"} | ft -Property UserPrincipalName,DisplayName,Department,Title,PhoneNumber,Office,PasswordNeverExpires,LastPasswordChangeTimestamp,LastDirSyncTime -Autosize | Out-String -Width 4096 | tee -FilePath .\${CURRENTJOB}.users_advanced.txt
Get-MsolUser -All |  Where-Object {$_.UserPrincipalName -notlike "HealthMailbox*"} | Select-Object -Property UserPrincipalName,DisplayName,Department,Title,PhoneNumber,Office,PasswordNeverExpires,LastPasswordChangeTimestamp,LastDirSyncTime | Export-Csv -Append -Path .\${CURRENTJOB}.users_advanced.csv

echo "-------------------------------------------"

## IF USER_LDAP IS SET -- this is each user entry ldap style
Get-MsolUser -All | Select-Object -Property * | tee -FilePath ./${CURRENTJOB}.users_detailed.txt
 
echo "-------------------------------------------"

## GROUPS FLAG - ON BY DEFAULT
# RETRIEVE GROUP NAMES

#old way
Get-MsolGroup -All | ft -Property CommonName | tee -FilePath ./${CURRENTJOB}.groups.txt

#new way
#Get-AzureADGroup -All | ft

echo "-------------------------------------------"

## GROUPS_ADVANCED FLAG - OFF BY DEFAULT
# RETRIEVE GROUP NAMES, DESCRIPTION, GROUP TYPE

#old way
Get-MsolGroup -All | ft -Property CommonName,Description,GroupType -Autosize | tee -FilePath .\${CURRENTJOB}.groups_advanced.txt


echo "-------------------------------------------"

## GROUP_MEMBERSHIP FLAG - ON BY DEFAULT
# get all group memberships

# old way but with enum4linux style group membership
Get-MsolGroup -All | % {
    $CURRENTGROUP=$_.DisplayName
    $memberlist=$(Get-MsolGroupMember -All -GroupObjectid $_.objectid); 
    if ($memberlist -ne $null){ 
        foreach ($item in $memberlist){
            echo "$($CURRENTGROUP):$($item.EmailAddress)" | tee -Append -FilePath .\${CURRENTJOB}.groupmembership.txt
        } 
    }else{ 
        "$($CURRENTGROUP): no group members found" 
        };
    echo "--------"
    }

