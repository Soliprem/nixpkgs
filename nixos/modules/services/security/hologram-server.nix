{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.hologram-server;

  cfgFile = pkgs.writeText "hologram-server.json" (
    builtins.toJSON {
      ldap = {
        host = cfg.ldapHost;
        bind = {
          dn = cfg.ldapBindDN;
          password = cfg.ldapBindPassword;
        };
        insecureldap = cfg.ldapInsecure;
        userattr = cfg.ldapUserAttr;
        baseDN = cfg.ldapBaseDN;
        enableldapRoles = cfg.enableLdapRoles;
        roleAttr = cfg.roleAttr;
        groupClassAttr = cfg.groupClassAttr;
      };
      aws = {
        account = cfg.awsAccount;
        defaultrole = cfg.awsDefaultRole;
      };
      stats = cfg.statsAddress;
      listen = cfg.listenAddress;
      cachetimeout = cfg.cacheTimeoutSeconds;
    }
  );
in
{
  options = {
    services.hologram-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Hologram server for AWS instance credentials";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0:3100";
        description = "Address and port to listen on";
      };

      ldapHost = mkOption {
        type = types.str;
        description = "Address of the LDAP server to use";
      };

      ldapInsecure = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to connect to LDAP over SSL or not";
      };

      ldapUserAttr = mkOption {
        type = types.str;
        default = "cn";
        description = "The LDAP attribute for usernames";
      };

      ldapBaseDN = mkOption {
        type = types.str;
        description = "The base DN for your Hologram users";
      };

      ldapBindDN = mkOption {
        type = types.str;
        description = "DN of account to use to query the LDAP server";
      };

      ldapBindPassword = mkOption {
        type = types.str;
        description = "Password of account to use to query the LDAP server";
      };

      enableLdapRoles = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to assign user roles based on the user's LDAP group memberships";
      };

      groupClassAttr = mkOption {
        type = types.str;
        default = "groupOfNames";
        description = "The objectclass attribute to search for groups when enableLdapRoles is true";
      };

      roleAttr = mkOption {
        type = types.str;
        default = "businessCategory";
        description = "Which LDAP group attribute to search for authorized role ARNs";
      };

      awsAccount = mkOption {
        type = types.str;
        description = "AWS account number";
      };

      awsDefaultRole = mkOption {
        type = types.str;
        description = "AWS default role";
      };

      statsAddress = mkOption {
        type = types.str;
        default = "";
        description = "Address of statsd server";
      };

      cacheTimeoutSeconds = mkOption {
        type = types.int;
        default = 3600;
        description = "How often (in seconds) to refresh the LDAP cache";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hologram-server = {
      description = "Provide EC2 instance credentials to machines outside of EC2";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.hologram}/bin/hologram-server --debug --conf ${cfgFile}";
      };
    };
  };
}
