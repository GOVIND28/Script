#!/bin/bash

PASS=true

# 1. Verify Users and Groups
echo "🔍 Verifying Users and Groups..."

getent passwd alice > /dev/null || { echo "❌ User 'alice' does not exist."; PASS=false; }
getent passwd bob > /dev/null || { echo "❌ User 'bob' does not exist."; PASS=false; }

getent group collabteam > /dev/null || { echo "❌ Group 'collabteam' does not exist."; PASS=false; }

groups alice | grep -qw collabteam || { echo "❌ User 'alice' is not in secondary group 'collabteam'."; PASS=false; }

id -gn bob | grep -qw collabteam || { echo "❌ Primary group of 'bob' is not 'collabteam'."; PASS=false; }

# 2. Verify Directory Setup
echo "🔍 Verifying Collaborative Directory..."

DIR="/project/collabX"

[ -d "$DIR" ] || { echo "❌ Directory $DIR does not exist."; PASS=false; }

OWNER=$(stat -c "%U" "$DIR")
GROUP=$(stat -c "%G" "$DIR")
PERM=$(stat -c "%A" "$DIR")
MODE=$(stat -c "%a" "$DIR")

[ "$GROUP" = "collabteam" ] || { echo "❌ Group ownership of $DIR is not 'collabteam'."; PASS=false; }

# Check permission: rwxrws--T or rwxrws--t
echo "$PERM" | grep -q 'rwxrws..[Tt]' || { echo "❌ Permissions or special bits on $DIR are incorrect ($PERM)."; PASS=false; }

# 3. File Management
echo "🔍 Verifying File Creation and Permissions..."

LOGFILE="$DIR/log.txt"

[ -f "$LOGFILE" ] || { echo "❌ File $LOGFILE not found."; PASS=false; }

CONTENT=$(head -n 1 "$LOGFILE")
echo "$CONTENT" | grep -q "Project collabX initiated." || { echo "❌ log.txt does not contain initial message."; PASS=false; }

LINES=$(wc -l < "$LOGFILE")
[ "$LINES" -ge 2 ] || { echo "❌ log.txt does not contain appended date."; PASS=false; }

PERM_LOG=$(stat -c "%a" "$LOGFILE")
[ "$PERM_LOG" = "600" ] || { echo "❌ log.txt permissions are not 600 (found $PERM_LOG)."; PASS=false; }

# Final Result
if [ "$PASS" = true ]; then
    echo "✅ All tasks verified successfully!"
else
    echo "❌ Some tasks failed verification."
    exit 1
fi

