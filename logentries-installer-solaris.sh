#!/bin/bash

clear
pushd /tmp/ >/dev/null 2>&1
svcadm disable logentries
clear

PROJECT=$(echo $HOSTNAME | cut -d'-' -f1)

function le_installer()
{
  le_acct_key="your-account-key"
  le_follow_log="your-log-path-to-file-name"
  le_log_name="your-log-name"
  le_log_type="ruby"

  reg_node="le register"
  reg_log="le follow"
  reg_stats="le whoami"

  echo -e "Installing logentries binary"
  wget -c https://raw.githubusercontent.com/riesal/bash-scripts/master/install-logentries.sh
  bash /tmp/install-logentries.sh
  chmod +x /opt/local/bin/le
  sed -i 's/python2/python/g' /opt/local/bin/le

  echo -e "\nRegistering the host and add the log files to follow."
  $reg_node --name="$HOSTNAME" --hostname="$HOSTNAME" --account-key="$le_acct_key" --force --suppress-ssl
  $reg_log "$le_follow_log" --name "$le_log_name" --type="$le_log_type" --suppress-ssl

  echo -e "\nApplying the settings.."
  svcadm disable logentries  svcadm enable logentries
  svcs | grep logentries
  echo -e "\nShow some stats.."
  $reg_stats
}

if [[ "$PROJECT" == "crdt" ]]; then
  PJRCT="CREDIT"
  le_installer
elif [[ "$PROJECT" == "payment" ]]; then
  PJRCT="CREDIT"
  le_installer
else
  echo "Installation halted, please define the correct PROJECT!"
fi

echo -e "\nCleanup the files.."
rm -f install-logentries.sh
popd >/dev/null 2>&1
