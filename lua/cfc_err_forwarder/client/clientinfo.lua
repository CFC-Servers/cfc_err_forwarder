local systemOS = system.IsWindows() and "windows" or system.IsLinux() and "linux" or system.IsOSX() and "osx" or "unknown"
CreateConVar( "cfc_err_forwarder_os", systemOS, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
CreateConVar( "cfc_err_forwarder_branch", BRANCH, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
CreateConVar( "cfc_err_forwarder_country", system.GetCountry(), { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
CreateConVar( "cfc_err_forwarder_gmodversion", VERSIONSTR, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
