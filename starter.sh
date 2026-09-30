#!/bin/bash

# ============================================================
# Linux Security Assignment
# Secure Departmental Directory
# ============================================================

set -e

# -----------------------------
# Configuration
# -----------------------------

GROUP_NAME="students"

USER1="student1"
USER2="student2"
UNAUTHORIZED="unauthorized"

BASE_DIR="/opt/department"
STUDENT_DIR="/opt/department/students"
TEST_FILE="/opt/department/students/student_info.txt"

SELINUX_TYPE="httpd_sys_content_t"

# httpd_sys_content_t is intended for content that Apache/httpd can read.
# This boolean allows httpd to read user home directories; it is not
# required merely to label /opt/department/students as httpd content.
SELINUX_BOOLEAN=""

echo "======================================"
echo " Linux Security Assignment"
echo "======================================"

# ------------------------------------------------------------
# TODO 1: Check that the script is running as root
# ------------------------------------------------------------

echo "[1] Checking root privileges..."

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# TODO 2: Check SELinux status
# ------------------------------------------------------------

echo "[2] Checking SELinux..."

if ! command -v getenforce >/dev/null 2>&1; then
    echo "ERROR: getenforce command not found."
    exit 1
fi

SELINUX_STATUS="$(getenforce)"

if [ "${SELINUX_STATUS}" != "Enforcing" ]; then
    echo "ERROR: SELinux must be enabled and enforcing."
    echo "Current status: ${SELINUX_STATUS}"
    exit 1
fi

echo "SELinux status: ${SELINUX_STATUS}"

# ------------------------------------------------------------
# TODO 3: Create the students group
# ------------------------------------------------------------

echo "[3] Creating group: ${GROUP_NAME}"

if ! getent group "${GROUP_NAME}" >/dev/null 2>&1; then
    groupadd "${GROUP_NAME}"
fi

# ------------------------------------------------------------
# TODO 4: Create users
# ------------------------------------------------------------

echo "[4] Creating users..."

if ! id "${USER1}" >/dev/null 2>&1; then
    useradd "${USER1}"
fi

if ! id "${USER2}" >/dev/null 2>&1; then
    useradd "${USER2}"
fi

if ! id "${UNAUTHORIZED}" >/dev/null 2>&1; then
    useradd "${UNAUTHORIZED}"
fi

# Add student1 and student2 to students group.
usermod -aG "${GROUP_NAME}" "${USER1}"
usermod -aG "${GROUP_NAME}" "${USER2}"

# Ensure unauthorized is NOT a member of students.
gpasswd -d "${UNAUTHORIZED}" "${GROUP_NAME}" 2>/dev/null || true

# ------------------------------------------------------------
# TODO 5: Create departmental directory
# ------------------------------------------------------------

echo "[5] Creating directory..."

mkdir -p "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 6: Configure ownership and permissions
# ------------------------------------------------------------

echo "[6] Configuring ownership and permissions..."

chown root:"${GROUP_NAME}" "${BASE_DIR}"
chown root:"${GROUP_NAME}" "${STUDENT_DIR}"

chmod 755 "${BASE_DIR}"
chmod 2770 "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 7: Create test file
# ------------------------------------------------------------

echo "[7] Creating test file..."

echo "Departmental student information." > "${TEST_FILE}"

chown root:"${GROUP_NAME}" "${TEST_FILE}"
chmod 660 "${TEST_FILE}"

# ------------------------------------------------------------
# TODO 8: Configure persistent SELinux file context
# ------------------------------------------------------------

echo "[8] Configuring SELinux file context..."

if ! command -v semanage >/dev/null 2>&1; then
    echo "ERROR: semanage is required."
    echo "Install the appropriate SELinux management package and rerun."
    exit 1
fi

# Remove an existing identical rule if present, then add the required rule.
semanage fcontext -a -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?" 2>/dev/null || \
semanage fcontext -m -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?"

restorecon -Rv "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 9: Configure SELinux boolean
# ------------------------------------------------------------

echo "[9] Configuring SELinux boolean..."

# No boolean is required for merely assigning httpd_sys_content_t.
# The directory's SELinux type is sufficient for normal httpd read access.
SELINUX_BOOLEAN=""

if [ -n "${SELINUX_BOOLEAN}" ]; then
    setsebool -P "${SELINUX_BOOLEAN}" on
else
    echo "No additional SELinux boolean required for ${SELINUX_TYPE}."
fi

# ------------------------------------------------------------
# TODO 10: Verification
# ------------------------------------------------------------

echo "[10] Verification"

echo
echo "Users:"
id "${USER1}" || true
id "${USER2}" || true
id "${UNAUTHORIZED}" || true

echo
echo "Directory:"
ls -ld "${STUDENT_DIR}" || true

echo
echo "Test file:"
ls -l "${TEST_FILE}" || true

echo
echo "SELinux context:"
ls -Zd "${STUDENT_DIR}" || true
ls -Z "${TEST_FILE}" || true

echo
echo "SELinux status:"
getenforce || true

echo
echo "Selected SELinux boolean:"
if [ -n "${SELINUX_BOOLEAN}" ]; then
    getsebool "${SELINUX_BOOLEAN}" || true
else
    echo "No additional boolean required"
fi

echo
echo "======================================"
echo " Script completed"
echo "======================================"
