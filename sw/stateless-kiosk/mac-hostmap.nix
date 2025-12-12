# Shared MAC address to station mapping and case builder for stateless-kiosk modules
{ lib }:
let
  hostmap = {
    "00:e0:4c:46:0b:32" = "1";
    "00:e0:4c:46:07:26" = "2";
    "00:e0:4c:46:05:94" = "3";
    "00:e0:4c:46:07:11" = "4";
    "00:e0:4c:46:08:02" = "5";
    "00:e0:4c:46:08:5c" = "6";
  };
  # macCaseBuilder: builds a shell case statement from a hostmap
  # varName: the shell variable to assign
  # prefix: optional string to prepend to the value (default: "")
  # attrset: attribute set to use (default: hostmap)
  macCaseBuilder = {
    varName,
    prefix ? "",
    attrset ? hostmap
  }:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (mac: val: "      ${mac}) ${varName}=${prefix}${val} ;;") attrset
    );
in 
{
  inherit hostmap macCaseBuilder;
}
