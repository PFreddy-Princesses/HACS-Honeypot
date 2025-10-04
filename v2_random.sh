#!/bin/bash

# ==============================================================================
# LXC FILE SERVER CONFIGURATION GENERATOR
# This script generates a small business file system inside an existing LXC container.
# It randomly selects one of 5 configurations with varying PII-suggesting file ratios.
# ==============================================================================

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <container_name>"
    exit 1
fi

LXC_CONTAINER_NAME="$1"
CONTAINER_TARGET_DIR="/opt/simulated_server"

# --- FILE CONTENT AND NAMING ARRAYS ---
FILE_EXTENSIONS=(".xlsx" ".pdf" ".docx" ".pptx")
PII_NAMES=(
    "Employee_SSN_List" "Client_Bank_Accounts" "Payroll_Records_Q2" "W2_Forms_2023" 
    "New_Hire_Onboarding" "Confidential_Salaries" "Tax_ID_Register" "Signed_Contracts_PII" 
    "Quarterly_Financials_SSN" "Address_Book_Vip" "Personal_Client_Data" "Sensitive_Logins"
)
GENERIC_NAMES=(
    "Project_Status_Q4" "Marketing_Budget" "Server_Log_Report" "Meeting_Notes" 
    "Draft_Memo" "Vendor_List_2024" "Travel_Expense_Policy" "Training_Schedule" 
    "Office_Supply_Order" "IT_Roadmap_Draft" "Website_Analytics" "Annual_Review_Template"
)
GREEK_WORDS=(
    "epsilon" "omicron" "gamma" "delta" "alpha" "beta" 
    "sigma" "lambda" "kappa" "rho" "tau" "upsilon" "chi" "psi" "lipon" "endaxi"
)

# --- CONFIGURATION RECIPES (PII Counts: 0, 10, 20, 30, 40) ---
# Format: "Title|PII_Count|Distribution_String"
RECIPES=(
    "Baseline: Zero Implied PII|0|Client_Financials:8 HR_Employee_Records:8 2024_Tax_Documents:8 Legal_Contracts:8 Marketing_And_Operations:8"
    "Low PII Implication (10 Files)|10|Client_Financials:10 HR_Employee_Records:6 2024_Tax_Documents:6 Legal_Contracts:8 Marketing_And_Operations:10"
    "Moderate PII Implication (20 Files)|20|Client_Financials:8 HR_Employee_Records:10 2024_Tax_Documents:8 Legal_Contracts:6 Marketing_And_Operations:8"
    "High PII Implication (30 Files)|30|Client_Financials:8 HR_Employee_Records:8 2024_Tax_Documents:10 Legal_Contracts:8 Marketing_And_Operations:6"
    "Critical PII Implication (40 Files)|40|Client_Financials:10 HR_Employee_Records:10 2024_Tax_Documents:5 Legal_Contracts:10 Marketing_And_Operations:5"
)

# --- VERIFICATION ---
check_container_exists() {
    if ! lxc info "${LXC_CONTAINER_NAME}" >/dev/null 2>&1; then
        echo "Error: Container '${LXC_CONTAINER_NAME}' does not exist."
        exit 1
    fi
    
    local status=$(lxc info "${LXC_CONTAINER_NAME}" | grep "Status:" | awk '{print $2}')
    if [ "${status}" != "Running" ]; then
        echo "Error: Container '${LXC_CONTAINER_NAME}' is not running (Status: ${status})."
        echo "Please start the container first with: lxc start ${LXC_CONTAINER_NAME}"
        exit 1
    fi
    
    echo "Container '${LXC_CONTAINER_NAME}' is running."
}

# --- MAIN EXECUTION ---
main() {
    echo "=== LXC File Server Configuration Generator ==="
    
    check_container_exists
    
    # Randomly select a configuration
    CONFIG_ID=$((RANDOM % ${#RECIPES[@]}))
    RECIPE_DATA="${RECIPES[CONFIG_ID]}"
    
    IFS='|' read -r TITLE PII_COUNT DIST_STRING <<< "${RECIPE_DATA}"
    GENERIC_COUNT=$((40 - PII_COUNT))
    
    echo "Selected Configuration #${CONFIG_ID}: ${TITLE}"
    echo "PII-suggesting files: ${PII_COUNT} | Generic files: ${GENERIC_COUNT}"
    echo "Target directory: ${CONTAINER_TARGET_DIR}"
    echo ""
    
    # Create the inline script that will run inside the container
    lxc exec "${LXC_CONTAINER_NAME}" -- /bin/bash <<INNERSCRIPT
set -euo pipefail

# Arrays and configuration
FILE_EXTENSIONS=(${FILE_EXTENSIONS[@]})
PII_NAMES=(${PII_NAMES[@]})
GENERIC_NAMES=(${GENERIC_NAMES[@]})
GREEK_WORDS=(${GREEK_WORDS[@]})

TARGET_DIR="${CONTAINER_TARGET_DIR}"
PII_COUNT=${PII_COUNT}
GENERIC_COUNT=${GENERIC_COUNT}
DIST_STRING="${DIST_STRING}"

# Helper function to generate random content
generate_content() {
    # Generate 50-200 random Greek words
    local word_count=\$((50 + RANDOM % 151))
    local content=""
    for ((i=0; i<word_count; i++)); do
        content+="\${GREEK_WORDS[\$((RANDOM % \${#GREEK_WORDS[@]}))]} "
    done
    echo "\$content"
}

# Helper function to get random suffix
get_random_suffix() {
    local suffix=\$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 4)
    local ext="\${FILE_EXTENSIONS[\$((RANDOM % \${#FILE_EXTENSIONS[@]}))]}"
    echo "_\${suffix}\${ext}"
}

echo "Creating file server structure at \${TARGET_DIR}..."
rm -rf "\${TARGET_DIR}"
mkdir -p "\${TARGET_DIR}"

# Generate complete list of file names
ALL_FILE_NAMES=()

# Add PII-suggesting names
for ((i=0; i<PII_COUNT; i++)); do
    NAME="\${PII_NAMES[\$((i % \${#PII_NAMES[@]}))]}\$(get_random_suffix)"
    ALL_FILE_NAMES+=("PII|\${NAME}")
done

# Add Generic names
for ((i=0; i<GENERIC_COUNT; i++)); do
    NAME="\${GENERIC_NAMES[\$((i % \${#GENERIC_NAMES[@]))]}\$(get_random_suffix)"
    ALL_FILE_NAMES+=("GENERIC|\${NAME}")
done

# Shuffle the names
SHUFFLED_NAMES=()
while [ \${#ALL_FILE_NAMES[@]} -gt 0 ]; do
    idx=\$((RANDOM % \${#ALL_FILE_NAMES[@]}))
    SHUFFLED_NAMES+=("\${ALL_FILE_NAMES[\$idx]}")
    unset 'ALL_FILE_NAMES[\$idx]'
    ALL_FILE_NAMES=("\${ALL_FILE_NAMES[@]}")
done

FILE_INDEX=0
TOTAL_CREATED=0

# Create directories and files according to distribution
for entry in \${DIST_STRING}; do
    IFS=':' read -r FOLDER_NAME FILE_COUNT <<< "\${entry}"
    FOLDER_PATH="\${TARGET_DIR}/\${FOLDER_NAME}"
    
    mkdir -p "\${FOLDER_PATH}"
    echo "Creating folder: \${FOLDER_NAME} (${FILE_COUNT} files)"
    
    for ((i=0; i<FILE_COUNT; i++)); do
        FILE_ENTRY="\${SHUFFLED_NAMES[\$FILE_INDEX]}"
        IFS='|' read -r TYPE FILENAME <<< "\${FILE_ENTRY}"
        
        CONTENT=\$(generate_content)
        echo "\$CONTENT" > "\${FOLDER_PATH}/\${FILENAME}"
        
        FILE_INDEX=\$((FILE_INDEX + 1))
        TOTAL_CREATED=\$((TOTAL_CREATED + 1))
    done
done

echo ""
echo "=== File Server Creation Complete ==="
echo "Total files created: \${TOTAL_CREATED}"
echo "Location: \${TARGET_DIR}"
echo ""
echo "Directory structure:"
ls -lh "\${TARGET_DIR}"
echo ""
echo "File counts per directory:"
for dir in "\${TARGET_DIR}"/*; do
    if [ -d "\$dir" ]; then
        count=\$(ls -1 "\$dir" | wc -l)
        echo "  \$(basename "\$dir"): \${count} files"
    fi
done
INNERSCRIPT

    echo ""
    echo "=== Generation Complete ==="
    echo "To view the file system:"
    echo "  lxc exec ${LXC_CONTAINER_NAME} -- ls -R ${CONTAINER_TARGET_DIR}"
    echo "To access the container:"
    echo "  lxc exec ${LXC_CONTAINER_NAME} -- /bin/bash"
}

# Execute main function
main
