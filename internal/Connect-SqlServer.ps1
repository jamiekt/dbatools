Function Connect-SqlServer
{
<# 
.SYNOPSIS 
Internal function that creates SMO server object. Input can be text or SMO.Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential,
		[switch]$ParameterConnection,
		[switch]$RegularUser
	)
	
	
	if ($SqlServer.GetType() -eq [Microsoft.SqlServer.Management.Smo.Server])
	{
		
		if ($ParameterConnection)
		{
			$paramserver = New-Object Microsoft.SqlServer.Management.Smo.Server
			$paramserver.ConnectionContext.ConnectTimeout = 2
			$paramserver.ConnectionContext.ApplicationName = "dbatools PowerShell module - dbatools.io"
			$paramserver.ConnectionContext.ConnectionString = $SqlServer.ConnectionContext.ConnectionString
			
			if ($SqlCredential.username -ne $null)
			{
				$username = ($SqlCredential.username).TrimStart("\")
				
				if ($username -like "*\*")
				{
					$username = $username.Split("\")[1]
					$authtype = "Windows Authentication with Credential"
					$server.ConnectionContext.LoginSecure = $true
					$server.ConnectionContext.ConnectAsUser = $true
					$server.ConnectionContext.ConnectAsUserName = $username
					$server.ConnectionContext.ConnectAsUserPassword = ($SqlCredential).GetNetworkCredential().Password
				}
				else
				{
					$authtype = "SQL Authentication"
					$server.ConnectionContext.LoginSecure = $false
					$server.ConnectionContext.set_Login($username)
					$server.ConnectionContext.set_SecurePassword($SqlCredential.Password)
				}
			}
			
			$paramserver.ConnectionContext.Connect()
			return $paramserver
		}
		
		if ($SqlServer.ConnectionContext.IsOpen -eq $false)
		{
			$SqlServer.ConnectionContext.Connect()
		}
		return $SqlServer
	}
	
	$server = New-Object Microsoft.SqlServer.Management.Smo.Server $SqlServer
	$server.ConnectionContext.ApplicationName = "dbatools PowerShell module - dbatools.io"
	
	try
	{
		if ($SqlCredential.username -ne $null)
		{
			$username = ($SqlCredential.username).TrimStart("\")
			
			if ($username -like "*\*")
			{
				$username = $username.Split("\")[1]
				$authtype = "Windows Authentication with Credential"
				$server.ConnectionContext.LoginSecure = $true
				$server.ConnectionContext.ConnectAsUser = $true
				$server.ConnectionContext.ConnectAsUserName = $username
				$server.ConnectionContext.ConnectAsUserPassword = ($SqlCredential).GetNetworkCredential().Password
			}
			else
			{
				$authtype = "SQL Authentication"
				$server.ConnectionContext.LoginSecure = $false
				$server.ConnectionContext.set_Login($username)
				$server.ConnectionContext.set_SecurePassword($SqlCredential.Password)
			}
		}
	}
	catch { }
	
	try
	{
		if ($ParameterConnection)
		{
			$server.ConnectionContext.ConnectTimeout = 2
		}
		else
		{
			$server.ConnectionContext.ConnectTimeout = 3
		}
		
		$server.ConnectionContext.Connect()
	}
	catch
	{
		$message = $_.Exception.InnerException.InnerException
		$message = $message.ToString()
		$message = ($message -Split '-->')[0]
		$message = ($message -Split 'at System.Data.SqlClient')[0]
		$message = ($message -Split 'at System.Data.ProviderBase')[0]
		throw "Can't connect to $sqlserver`: $message "
	}
	
	if ($RegularUser -eq $false)
	{
		if ($server.ConnectionContext.FixedServerRoles -notmatch "SysAdmin")
		{
			throw "Not a sysadmin on $SqlServer. Quitting."
		}
	}
	
	if ($ParameterConnection -eq $false)
	{
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Trigger], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.DatabaseDdlTrigger], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Default], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.DatabaseRole], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Rule], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Schema], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.SqlAssembly], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Table], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.View], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.StoredProcedure], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.UserDefinedAggregate], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.UserDefinedDataType], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.UserDefinedTableType], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.UserDefinedType], 'IsSystemObject')
		$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.UserDefinedFunction], 'IsSystemObject')
		
		if ($server.VersionMajor -eq 8)
		{
			# 2000
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], 'ReplicationOptions', 'Collation', 'CompatibilityLevel', 'CreateDate', 'ID', 'IsAccessible', 'IsFullTextEnabled', 'IsUpdateable', 'LastBackupDate', 'LastDifferentialBackupDate', 'LastLogBackupDate', 'Name', 'Owner', 'PrimaryFilePath', 'ReadOnly', 'RecoveryModel', 'Status', 'Version')
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Login], 'CreateDate', 'DateLastModified', 'DefaultDatabase', 'DenyWindowsLogin', 'IsSystemObject', 'Language', 'LanguageAlias', 'LoginType', 'Name', 'Sid', 'WindowsLoginAccessType')
		}
		
		
		elseif ($server.VersionMajor -eq 9 -or $server.VersionMajor -eq 10)
		{
			# 2005 and 2008
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], 'ReplicationOptions', 'BrokerEnabled', 'Collation', 'CompatibilityLevel', 'CreateDate', 'ID', 'IsAccessible', 'IsFullTextEnabled', 'IsMirroringEnabled', 'IsUpdateable', 'LastBackupDate', 'LastDifferentialBackupDate', 'LastLogBackupDate', 'Name', 'Owner', 'PrimaryFilePath', 'ReadOnly', 'RecoveryModel', 'Status', 'Trustworthy', 'Version')
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Login], 'AsymmetricKey', 'Certificate', 'CreateDate', 'Credential', 'DateLastModified', 'DefaultDatabase', 'DenyWindowsLogin', 'ID', 'IsDisabled', 'IsLocked', 'IsPasswordExpired', 'IsSystemObject', 'Language', 'LanguageAlias', 'LoginType', 'MustChangePassword', 'Name', 'PasswordExpirationEnabled', 'PasswordPolicyEnforced', 'Sid', 'WindowsLoginAccessType')
		}
		
		else
		{
			# 2012 and above
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], 'ReplicationOptions', 'ActiveConnections', 'AvailabilityDatabaseSynchronizationState', 'AvailabilityGroupName', 'BrokerEnabled', 'Collation', 'CompatibilityLevel', 'ContainmentType', 'CreateDate', 'ID', 'IsAccessible', 'IsFullTextEnabled', 'IsMirroringEnabled', 'IsUpdateable', 'LastBackupDate', 'LastDifferentialBackupDate', 'LastLogBackupDate', 'Name', 'Owner', 'PrimaryFilePath', 'ReadOnly', 'RecoveryModel', 'Status', 'Trustworthy', 'Version')
			$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Login], 'AsymmetricKey', 'Certificate', 'CreateDate', 'Credential', 'DateLastModified', 'DefaultDatabase', 'DenyWindowsLogin', 'ID', 'IsDisabled', 'IsLocked', 'IsPasswordExpired', 'IsSystemObject', 'Language', 'LanguageAlias', 'LoginType', 'MustChangePassword', 'Name', 'PasswordExpirationEnabled', 'PasswordHashAlgorithm', 'PasswordPolicyEnforced', 'Sid', 'WindowsLoginAccessType')
		}
	}
	
	return $server
}