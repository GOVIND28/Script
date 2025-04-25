#!/bin/bash

echo "🔍 Starting useradd task verification..."

# Helper to log task titles
log_task() {
    echo -e "\n🧩 $1"
}

# 1️⃣ devuser: Home dir + bash shell + default files
log_task "Verifying devuser (home dir + bash + default files)"
if id devuser &>/dev/null; then
    echo "✅ devuser exists."
    shell=$(getent passwd devuser | cut -d: -f7)
    if [[ "$shell" == "/bin/bash" ]]; then
        echo "✅ Shell is /bin/bash."
    else
        echo "❌ Shell is $shell (expected: /bin/bash)"
    fi

    home="/home/devuser"
    if [[ -d "$home" ]]; then
        echo "✅ Home directory $home exists."
        if [[ -f "$home/.bashrc" && -f "$home/.profile" ]]; then
            echo "✅ Default files (.bashrc, .profile) are present in $home."
        else
            echo "❌ Default files missing in $home."
        fi
    else
        echo "❌ Home directory $home does NOT exist."
    fi
else
    echo "❌ devuser does NOT exist."
fi

# 2️⃣ projectx: UID 1050, primary group developers, shell /bin/sh
log_task "Verifying projectx (UID 1050, group 'developers', shell /bin/sh)"
if id projectx &>/dev/null; then
    echo "✅ projectx exists."
    
    uid=$(id -u projectx)
    if [[ "$uid" == "1050" ]]; then
        echo "✅ UID is 1050."
    else
        echo "❌ UID is $uid (expected 1050)"
    fi

    gid=$(id -g projectx)
    dev_gid=$(getent group developers | cut -d: -f3)
    if [[ "$gid" == "$dev_gid" ]]; then
        echo "✅ Primary group is 'developers'."
    else
        echo "❌ Primary group ID is $gid (expected: $dev_gid for developers)"
    fi

    shell=$(getent passwd projectx | cut -d: -f7)
    if [[ "$shell" == "/bin/sh" ]]; then
        echo "✅ Shell is /bin/sh."
    else
        echo "❌ Shell is $shell (expected: /bin/sh)"
    fi
else
    echo "❌ projectx does NOT exist."
fi

# 3️⃣ intern: supplementary groups testers & support
log_task "Verifying intern (groups: testers, support)"
if id intern &>/dev/null; then
    echo "✅ intern exists."
    groups=$(id -nG intern)
    for g in testers support; do
        if echo "$groups" | grep -qw "$g"; then
            echo "✅ Member of group '$g'."
        else
            echo "❌ NOT in group '$g'."
        fi
    done
else
    echo "❌ intern does NOT exist."
fi

# 4️⃣ trainer: no home directory should exist
log_task "Verifying trainer (no home directory)"
if id trainer &>/dev/null; then
    echo "✅ trainer exists."
    home=$(getent passwd trainer | cut -d: -f6)
    if [[ ! -d "$home" ]]; then
        echo "✅ Home directory $home does NOT exist (as expected)."
    else
        echo "❌ Home directory $home exists (should NOT exist)."
    fi
else
    echo "❌ trainer does NOT exist."
fi

# 5️⃣ backupuser: account expiration after 10 days
log_task "Verifying backupuser (expiration set)"
if id backupuser &>/dev/null; then
    echo "✅ backupuser exists."
    expiry=$(chage -l backupuser | grep "Account expires" | cut -d: -f2 | xargs)

    if [[ "$expiry" != "never" && "$expiry" != "" ]]; then
        expiry_sec=$(date -d "$expiry" +%s)
        today_sec=$(date +%s)
        diff_days=$(( (expiry_sec - today_sec) / 86400 ))

        if [[ $diff_days -le 10 && $diff_days -ge 9 ]]; then
            echo "✅ Expiration set correctly: $expiry ($diff_days days from today)"
        else
            echo "❌ Expiration is $expiry ($diff_days days from today, expected ~10)"
        fi
    else
        echo "❌ No expiration date set."
    fi
else
    echo "❌ backupuser does NOT exist."
fi

echo -e "\n🎯 Verification complete."
echo "Design and Develop By Govind Ambade...:)"
