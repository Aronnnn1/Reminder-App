#!/bin/bash

# Enable debugging and redirect errors to a log file
set -x  # Debugging mode
exec 2>>error.log  # Redirect errors to error.log for analysis

# Define the directories where reminders and todos will be stored
REMINDERS_DIR=~/calendar_reminder/reminders
TODOS_DIR=~/calendar_reminder/todos

# Function to check the validity of a file descriptor (FD)
check_fd() {
    if ! [ -e /proc/$$/fd/9 ]; then
        echo "File descriptor 9 is invalid or closed" >>error.log
    fi
}

# Function to display the calendar for the user to choose a date
choose_date() {
    check_fd  # Debug FD before using
    SELECTED_DATE=$(zenity --calendar --title="Select a Date" --text="Pick a date for reminder/to-do list" --date-format="%Y-%m-%d")
    if [ $? -eq 0 ]; then
        echo "You selected $SELECTED_DATE"
    else
        zenity --error --text="No date selected."
        exit 1
    fi
}

# Function to set a reminder for the selected date
set_reminder() {
    check_fd  # Debug FD before using
    REMINDER=$(zenity --entry --title="Set Reminder" --text="Enter your reminder for $SELECTED_DATE:")
    if [ ! -z "$REMINDER" ]; then
        REMINDER_FILE="$REMINDERS_DIR/$SELECTED_DATE.txt"
        echo "$REMINDER" >> "$REMINDER_FILE"
        zenity --info --text="Reminder for $SELECTED_DATE added."
    else
        zenity --error --text="Reminder cannot be empty."
    fi
}

# Function to display the reminder for the selected date
show_reminders() {
    check_fd  # Debug FD before using
    REMINDER_FILE="$REMINDERS_DIR/$SELECTED_DATE.txt"
    if [ -f "$REMINDER_FILE" ]; then
        REMINDERS=$(cat "$REMINDER_FILE")
        zenity --info --title="Reminders for $SELECTED_DATE" --text="$REMINDERS"
    else
        zenity --info --text="No reminders for $SELECTED_DATE."
    fi
}

# Function to set a to-do list for the selected date
set_todo() {
    check_fd  # Debug FD before using
    TODO=$(zenity --entry --title="Set To-Do List" --text="Enter a to-do item for $SELECTED_DATE:")
    if [ ! -z "$TODO" ]; then
        TODO_FILE="$TODOS_DIR/$SELECTED_DATE.txt"
        echo "$TODO" >> "$TODO_FILE"
        zenity --info --text="To-do item for $SELECTED_DATE added."
    else
        zenity --error --text="To-do item cannot be empty."
    fi
}

# Function to show the to-do list for the selected date
show_todos() {
    check_fd  # Debug FD before using
    TODO_FILE="$TODOS_DIR/$SELECTED_DATE.txt"
    if [ -f "$TODO_FILE" ]; then
        TODOS=$(cat "$TODO_FILE")
        zenity --info --title="To-Do List for $SELECTED_DATE" --text="$TODOS"
    else
        zenity --info --text="No to-do items for $SELECTED_DATE."
    fi
}

# Function to delete a to-do item
delete_todo() {
    check_fd  # Debug FD before using
    TODO_FILE="$TODOS_DIR/$SELECTED_DATE.txt"
    if [ -f "$TODO_FILE" ]; then
        TODOS=$(cat "$TODO_FILE")
        SELECTED_TODO=$(echo "$TODOS" | zenity --list --title="Delete To-Do Item" --text="Select a to-do item to delete:" --column="To-Do Items")
        
        if [ $? -eq 0 ] && [ ! -z "$SELECTED_TODO" ]; then
            CONFIRM=$(zenity --question --title="Confirm Delete" --text="Are you sure you want to delete:\n$SELECTED_TODO?" --ok-label="Yes" --cancel-label="No")
            if [ $? -eq 0 ]; then
                grep -vFx "$SELECTED_TODO" "$TODO_FILE" > temp_file && mv temp_file "$TODO_FILE"
                zenity --info --text="To-do item deleted successfully."
            else
                zenity --info --text="Deletion canceled."
            fi
        else
            zenity --error --text="No to-do item selected for deletion."
        fi
    else
        zenity --info --text="No to-do items for $SELECTED_DATE."
    fi
}

# Function to show all reminders and todos with dates
show_all() {
    OUTPUT="All Reminders and To-Do Items:\n\n"

    if [ -d "$REMINDERS_DIR" ] && [ "$(ls -A "$REMINDERS_DIR")" ]; then
        for file in "$REMINDERS_DIR"/*; do
            DATE=$(basename "$file" .txt)
            CONTENT=$(cat "$file")
            OUTPUT+="Reminders for $DATE:\n$CONTENT\n\n"
        done
    else
        OUTPUT+="No reminders found.\n\n"
    fi
    
    # Add todos
    if [ -d "$TODOS_DIR" ] && [ "$(ls -A "$TODOS_DIR")" ]; then
        for file in "$TODOS_DIR"/*; do
            DATE=$(basename "$file" .txt)
            CONTENT=$(cat "$file")
            OUTPUT+="To-Do Items for $DATE:\n$CONTENT\n\n"
        done
    else
        OUTPUT+="No to-do items found.\n\n"
    fi

    echo "$OUTPUT"
    # Check if the output is non-empty and pass it correctly to zenity
    if [ -n "$OUTPUT" ]; then
        zenity --info --title="All Reminders and To-Do Items" --width=600 --height=400 --text="$(printf "$OUTPUT")"
    else
        zenity --info --title="All Reminders and To-Do Items" --text="No reminders or to-do items found."
    fi
}


# Main loop to interact with the user
while true; do
    check_fd  # Debug FD at the start of each loop
    ACTION=$(zenity --list --title="Calendar and Reminder App" --column="Action" \
        "Select Date" \
        "Set Reminder" \
        "Show Reminders" \
        "Set To-Do List" \
        "Show To-Do List" \
        "Delete To-Do Item" \
        "Show All Reminders and To-Do Items" \
        "Exit")

    case $ACTION in
        "Select Date")
            choose_date
            ;;
        "Set Reminder")
            set_reminder
            ;;
        "Show Reminders")
            show_reminders
            ;;
        "Set To-Do List")
            set_todo
            ;;
        "Show To-Do List")
            show_todos
            ;;
        "Delete To-Do Item")
            delete_todo
            ;;
        "Show All Reminders and To-Do Items")
            show_all
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --text="Invalid option."
            ;;
    esac
done
