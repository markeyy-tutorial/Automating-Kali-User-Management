#!/bin/bash

# Check if the script is run as root (superuser)
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

# Input file format
# The file should contain lines in the format:
# action:username:password:group1,group2,...
# action can be "create", "delete", or "update"

INPUT_FILE="userList"

# Function to create user and set password
create_user() {
    local username=$1
    local password=$2
    local groups=$3

    # Create user with the specified username
    useradd -m "$username"

    # Set the password for the user
    echo "$username:$password" | chpasswd

    # Add user to groups
    for group in $(echo "$groups" | tr ',' ' '); do
        usermod -aG "$group" "$username"
    done

    echo "User $username created and added to groups: $groups"
}

# Function to delete a user
delete_user() {
    local username=$1

    # Delete the user (with their home directory and mail spool)
    userdel -r "$username"

    echo "User $username deleted"
}

# Function to update a user's password and/or groups
update_user() {
    local username=$1
    local password=$2
    local groups=$3

    # Update password for the user
    echo "$username:$password" | chpasswd

    # Update groups (if necessary)
    if [[ -n "$groups" ]]; then
        # First, remove user from all groups
        gpasswd -d "$username" $(groups "$username" | cut -d' ' -f2-)

        # Add user to new groups
        for group in $(echo "$groups" | tr ',' ' '); do
            usermod -aG "$group" "$username"
        done
    fi

    echo "User $username updated with new password and groups"
}

# Check if input file exists
if [[ ! -f $INPUT_FILE ]]; then
    echo "Input file $INPUT_FILE not found!"
    exit 1
fi

# Loop through each line in the input file
while IFS=':' read -r action username password groups; do
    # Skip empty lines and comments
    if [[ -z "$username" || "$username" =~ ^# ]]; then
        continue
    fi

    # Perform action based on the first field
    case "$action" in
        "create")
            create_user "$username" "$password" "$groups"
            ;;
        "delete")
            delete_user "$username"
            ;;
        "update")
            update_user "$username" "$password" "$groups"
            ;;
        *)
            echo "Unknown action: $action for user $username"
            ;;
    esac
done < "$INPUT_FILE"

echo "Operations completed."
