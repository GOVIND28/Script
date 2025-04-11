#!/bin/bash

# This script must be run as root
echo "🔍 Verifying setup for user 'supportuser'..."

pass=0
fail=0

function result() {
    local msg="$1"
    local ok="$2"
    if [[ $ok -eq 0 ]]; then
        echo "[PASS] $msg"
        ((pass++))
    else
        echo "[FAIL] $msg"
        ((fail++))
    fi
}

# 1. Check if user exists
id supportuser &>/dev/null
result "User 'supportuser' exists" $?

# 2. Check password using su + expect (require expect installed)
echo "Redhat@123" | su - supportuser -c "whoami" &>/dev/null
result "'supportuser' password works (Redhat@123)" $?

# 3. Check allowed sudo commands
su - supportuser -c "sudo mkdir /tmp/testfolder" &>/dev/null
result "'sudo mkdir' allowed" $?

su - supportuser -c "sudo cat /etc/passwd" &>/dev/null
result "'sudo cat' allowed" $?

# 4. Check denied sudo commands
su - supportuser -c "sudo rm -rf /tmp/testfolder" &>/dev/null
[[ $? -ne 0 ]]
result "'sudo rm' correctly denied" $?

su - supportuser -c "sudo useradd testuser" &>/dev/null
[[ $? -ne 0 ]]
result "'sudo useradd' correctly denied" $?

su - supportuser -c "sudo nano /etc/passwd" &>/dev/null
[[ $? -ne 0 ]]
result "'sudo nano' correctly denied" $?

# 5. Check sudoers file syntax and path
grep -q 'supportuser ALL=(ALL) NOPASSWD: /bin/mkdir, /bin/cat' /etc/sudoers.d/supportuser
result "Correct sudoers rule exists in /etc/sudoers.d/supportuser" $?

echo
echo "✅ Passed: $pass"
echo "❌ Failed: $fail"

if [[ $fail -eq 0 ]]; then
    echo "🎉 All checks passed. Configuration is correct!"
else
    echo "⚠️ Some checks failed. Please review the sudoers configuration or user setup."
fi

