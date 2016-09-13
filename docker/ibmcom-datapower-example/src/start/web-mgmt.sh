{
  if [ "$DP_WEB_MGMT" = "true" ]
  then
    cat <<-EOF
	top; co

	web-mgmt
	  reset
	  system-read-only
	  admin enabled
	  idle-timeout 0
	exit
	EOF
  else
    cat <<-EOF
	top; co

	web-mgmt
	  admin disabled
	  system-read-only
	exit
	EOF
  fi
} | tee /drouter/config/web-mgmt.cfg
