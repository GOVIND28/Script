import os
import pwd
import grp
import spwd
import crypt

# ANSI color codes
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"

EXPECTED_PASSWORDS = {
    "alice": "devPass123",
    "bob": "qaSecure",
    "charlie": "docWriter123"
}

SUDOERS_VALIDATIONS = {
    "engineering_team": {
        "required_lines": [
            "%engineering_team ALL=(ALL) NOPASSWD: /bin/mkdir, /bin/rmdir, /bin/rm -r"
        ]
    },
    "bob_tail": {
        "required_lines": [
            "bob ALL=(ALL) NOPASSWD: /usr/bin/tail -n 100"
        ]
    },
    "doc_team": {
        "required_lines": [
            "%doc_team ALL=(ALL) NOPASSWD: /bin/cat"
        ]
    }
}

def check_user_exists(username):
    try:
        pwd.getpwnam(username)
        return True
    except KeyError:
        return False

def check_group_exists(groupname):
    try:
        grp.getgrnam(groupname)
        return True
    except KeyError:
        return False

def check_user_in_group(username, groupname):
    try:
        groups = [g.gr_name for g in grp.getgrall() if username in g.gr_mem]
        primary_group = grp.getgrgid(pwd.getpwnam(username).pw_gid).gr_name
        return groupname in groups or groupname == primary_group
    except KeyError:
        return False

def check_home_directory(username, expected_path):
    try:
        return pwd.getpwnam(username).pw_dir == expected_path
    except KeyError:
        return False

def check_shell(username, expected_shell):
    try:
        return pwd.getpwnam(username).pw_shell == expected_shell
    except KeyError:
        return False

def check_comment(username, expected_comment):
    try:
        return pwd.getpwnam(username).pw_gecos.startswith(expected_comment)
    except KeyError:
        return False

def check_group_gid(groupname, expected_gid):
    try:
        return grp.getgrnam(groupname).gr_gid == expected_gid
    except KeyError:
        return False

def check_user_password(username, expected_password):
    try:
        shadow = spwd.getspnam(username)
        encrypted = shadow.sp_pwdp
        return crypt.crypt(expected_password, encrypted) == encrypted
    except Exception:
        return False

def validate_sudoers_file(filename, expected_lines):
    path = f"/etc/sudoers.d/{filename}"
    if not os.path.isfile(path):
        return False, "File not found"

    try:
        with open(path, 'r') as file:
            content = file.read()
    except Exception as e:
        return False, f"Read error: {e}"

    for line in expected_lines:
        if line not in content:
            return False, f"Missing line: {line}"

    return True, ""

def print_result(description, result, message=""):
    color = GREEN if result else RED
    status = "✔ PASS" if result else "✖ FAIL"
    extra = f" ({message})" if message and not result else ""
    print(f"{color}{status}{RESET}: {description}{extra}")

def run_verification():
    print("=== Verifying Development Server Setup ===\n")

    tests = [
        ("Group engineering_team exists", check_group_exists("engineering_team")),
        ("Group qa_team exists", check_group_exists("qa_team")),
        ("Group doc_team exists", check_group_exists("doc_team")),
        ("Group build_admins exists", check_group_exists("build_admins")),
        ("Group archive_admins exists", check_group_exists("archive_admins")),
        ("Group staging exists", check_group_exists("staging")),

        ("User alice exists", check_user_exists("alice")),
        ("User bob exists", check_user_exists("bob")),
        ("User charlie exists", check_user_exists("charlie")),

        ("Alice in engineering_team", check_user_in_group("alice", "engineering_team")),
        ("Alice in build_admins", check_user_in_group("alice", "build_admins")),
        ("Bob in qa_team", check_user_in_group("bob", "qa_team")),
        ("Charlie in doc_team", check_user_in_group("charlie", "doc_team")),

        ("Alice home is /opt/alice_dev", check_home_directory("alice", "/opt/alice_dev")),
        ("Bob home is /opt/qa_area/bob", check_home_directory("bob", "/opt/qa_area/bob")),
        ("Charlie home is /home/charlie", check_home_directory("charlie", "/home/charlie")),

        ("Charlie shell is /bin/bash", check_shell("charlie", "/bin/bash")),
        ("Alice has correct comment", check_comment("alice", "Senior Application Developer")),

        ("qa_team GID is 4000", check_group_gid("qa_team", 4000)),
        ("doc_team GID is 4100", check_group_gid("doc_team", 4100)),
        ("archive_admins GID is 4300", check_group_gid("archive_admins", 4300)),
        ("staging GID is 4200", check_group_gid("staging", 4200)),

        ("Alice password is correct", check_user_password("alice", EXPECTED_PASSWORDS["alice"])),
        ("Bob password is correct", check_user_password("bob", EXPECTED_PASSWORDS["bob"])),
        ("Charlie password is correct", check_user_password("charlie", EXPECTED_PASSWORDS["charlie"])),
    ]

    passed = 0
    for description, result in tests:
        print_result(description, result)
        passed += result

    print("\n--- Verifying Sudoers Configuration Rules ---\n")

    for filename, data in SUDOERS_VALIDATIONS.items():
        result, msg = validate_sudoers_file(filename, data["required_lines"])
        print_result(f"Sudoers rules in {filename}", result, msg)
        passed += result

    total_tests = len(tests) + len(SUDOERS_VALIDATIONS)
    print(f"\n✅ {passed} out of {total_tests} checks passed.")
    print("\n✨ Developed by Govind 💻✨🚀")

if __name__ == "__main__":
    run_verification()
