{ mkEnvHook
, pkgs
, cyrus_sasl
}:

let
  targetPkgs = if pkgs ? pkgsTargetTarget then pkgs.pkgsTargetTarget else pkgs;
  isStatic = pkgs.stdenv.hostPlatform.isStatic or false;

  # Override cyrus_sasl to disable PAM for static builds (linux-pam is not available for static targets)
  cyrus_sasl_base = targetPkgs.cyrus_sasl or cyrus_sasl;
  cyrus_sasl_overridden = if cyrus_sasl_base ? override then
    cyrus_sasl_base.override ({
      enableLdap = false;
    } // (if isStatic then { pam = null; } else {}))
  else
    cyrus_sasl_base;
  cyrus_sasl_no_db_target = cyrus_sasl_overridden.overrideAttrs (old: {
    configureFlags = (old.configureFlags or []) ++ [
      "--disable-sasldb"
      "--with-dblib=none"
    ] ++ (if isStatic then [ "--disable-login" "--disable-gssapi" ] else []);
  });
in
mkEnvHook {
  name = "sasl2-sys";
  propagatedBuildInputs = [ pkgs.pkgsBuildHost.pkg-config ];
  depsTargetTargetPropagated = [ cyrus_sasl_no_db_target ];
}
